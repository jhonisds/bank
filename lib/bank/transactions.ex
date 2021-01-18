defmodule Bank.Transactions do
  @moduledoc """
  Module that provides banking transactions.
  The following transactions are available: `deposit`, `withdraw`, `transfer`, `split` and `exchange`.
  """

  alias Bank.Accounts
  alias Ecto.Changeset

  @doc """
  Transaction `deposit`.

  ## Examples

      iex> {:ok, account} = Accounts.create_account(%{account_owner: "Tupac"})
      iex> Transactions.deposit(account.id, 100)
      {:ok, "successfuly deposit transaction - current balance: #{Money.new(100, :BRL)}"}

      iex> Transactions.deposit(99, 100)
      {:error, "account: 99 not found"}
  """
  def deposit(account_id, amount, currency \\ :BRL) do
    amount
    |> is_valid_amount?(account_id, :deposit)
    |> transaction(currency)
  end

  @doc """
  Transaction `withdraw`.

  ## Examples

      iex> {:ok, account} = Accounts.create_account(%{account_owner: "Tupac", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> Transactions.withdraw(account.id, 100)
      {:ok, "successfuly withdraw transaction - current balance: #{Money.new(400, :BRL)}"}

      iex> {:ok, account} = Accounts.create_account(%{account_owner: "Tupac", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> Transactions.withdraw(account.id, 1000)
      {:error, "sorry, you don't have enought balance - current balance: #{Money.new(500, :BRL)}"}
  """
  def withdraw(account_id, amount) do
    amount
    |> is_valid_amount?(account_id, :withdraw)
    |> transaction(:BRL)
  end

  @doc """
  Transaction `transfer`.

  ## Examples

      iex> {:ok, account1} = Accounts.create_account(%{account_owner: "Tupac", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> {:ok, account2} = Accounts.create_account(%{account_owner: "Dre", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> Transactions.transfer(account1.id, account2.id, 200)
      {:ok, "successfuly transfer #{Money.new(200, :BRL)} to Dre - current balance: #{
    Money.new(300, :BRL)
  }"}

      iex> {:ok, account1} = Accounts.create_account(%{account_owner: "Tupac", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> {:ok, account2} = Accounts.create_account(%{account_owner: "Dre", currency: Money.new(:USD, 500), balance: "U$ 500,00" })
      iex> Transactions.transfer(account1.id, account2.id, 100)
      {:error, "cannot transfer monies with different currencies"}
  """
  def transfer(from_account, to_account, amount) do
    case from_account != to_account do
      true ->
        amount
        |> is_valid_amount?(from_account, :withdraw)
        |> do_transfer(from_account, to_account)

      false ->
        {:error, "same account - choose another account to transfer"}
    end
  end

  @doc """
  Transaction `split`.

  ## Examples

      iex> {:ok, account1} = Accounts.create_account(%{account_owner: "Tupac", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> {:ok, account2} = Accounts.create_account(%{account_owner: "Dre", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> Transactions.split(account1.id, [account2.id], 200)
      [{:ok, "successfuly transfer #{Money.new(200, :BRL)} to Dre - current balance: #{
    Money.new(300, :BRL)
  }"}]

      iex> {:ok, account1} = Accounts.create_account(%{account_owner: "Tupac", currency: Money.new(:BRL, 500), balance: "R$ 500,00" })
      iex> Transactions.transfer(account1.id, account1.id, 100)
      {:error, "same account - choose another account to transfer"}
  """
  def split(from_account, accounts, amount) do
    id = for x <- Accounts.list_accounts(), do: x.id

    elements =
      accounts
      |> Enum.filter(fn el ->
        Enum.member?(id, el)
      end)

    Enum.map(elements, &transfer(from_account, &1, amount / Enum.count(elements)))
  end

  @doc """
  Transaction `exchange`.

  ## Examples

      iex> Transactions.exchange(:BRL, :ERROR, 100)
      {Cldr.UnknownCurrencyError, "The currency :ERROR is invalid"}
  """
  def exchange(from_currency, to_currency, amount) do
    value = cast(amount)

    case Decimal.gt?(value, 0) do
      true ->
        value
        |> Money.new(from_currency)
        |> Money.to_currency(to_currency)
        |> case do
          {:ok, currency} ->
            {:ok, "successfuly exchange: #{Money.to_string(currency) |> elem(1)}"}

          {:error, reason} ->
            reason
        end

      false ->
        raise(ArgumentError, message: "amount #{value} is not allowed for exchange")
    end
  end

  defp is_valid_amount?(amount, id, opts) do
    account = Accounts.get_account!(id)

    result = cast(amount)

    result
    |> Decimal.gt?(0)
    |> case do
      true ->
        case opts do
          :deposit ->
            {:ok, %{amount: result, operation: opts, account: account}}

          :withdraw ->
            result
            |> has_balance?(account, opts)
        end

      false ->
        raise(ArgumentError, message: "amount #{amount} is not allowed for #{opts}")
    end
  rescue
    _e in Ecto.NoResultsError ->
      {:error, "account: #{id} not found"}
  end

  defp cast(amount) do
    amount
    |> Decimal.cast()
    |> elem(1)
  end

  defp has_balance?(amount, account, opts) do
    account.currency
    |> Money.to_decimal()
    |> Decimal.sub(amount)
    |> Decimal.negative?()
    |> case do
      true ->
        {:error, "sorry, you don't have enought balance - current balance: #{account.currency}"}

      false ->
        {:ok, %{amount: amount, operation: opts, account: account}}
    end
  end

  defp transaction({:ok, attrs}, currency) do
    attrs[:amount]
    |> Money.new(
      if attrs[:operation] == :withdraw,
        do: get_currency(attrs[:account].currency),
        else: currency
    )
    |> case do
      {:error, {_, reason}} ->
        {:error, reason}

      result ->
        result
        |> operation(attrs[:account], attrs[:operation])
        |> update_balance(attrs[:account].id, attrs[:operation])
    end
  end

  defp transaction({:error, reason}, _currency), do: {:error, reason}

  defp get_currency(%Money{amount: _, currency: currency}), do: currency

  defp update_balance(attrs, id, opts) do
    case attrs do
      {:error, reason} ->
        {:error, reason}

      changeset ->
        case Accounts.update_account(id, changeset) do
          {:ok, account} ->
            {:ok, "successfuly #{opts} transaction - current balance: #{account.balance}"}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp operation(amount, account, :deposit) do
    account.currency
    |> Money.add(amount)
    |> update_attrs()
  end

  defp operation(amount, account, :withdraw) do
    account.currency
    |> Money.sub(amount)
    |> update_attrs()
  end

  defp do_transfer({:error, reason}, _, _), do: {:error, reason}

  defp do_transfer({:ok, attrs}, from_account, to_account) do
    amount =
      attrs[:amount]
      |> Money.new(get_currency(attrs[:account].currency))

    from = Accounts.get_account!(from_account)
    to = Accounts.get_account!(to_account)

    from_attrs = Changeset.change(from, operation(amount, from, :withdraw))
    to_attrs = Changeset.change(to, operation(amount, to, :deposit))

    case Accounts.update_multi(from_attrs, to_attrs) do
      {:ok, _} ->
        {:ok,
         "successfuly transfer #{amount} to #{to.account_owner} - current balance: #{
           from_attrs.changes.balance
         }"}

      {:error, :from_account, changeset, _} ->
        {:error, changeset}

      {:error, :to_account, changeset, _} ->
        {:error, changeset}
    end
  rescue
    _e in FunctionClauseError ->
      {:error, "cannot transfer monies with different currencies"}

    _e in Ecto.NoResultsError ->
      {:error, "account: #{to_account} not found"}
  end

  defp update_attrs({:error, {_, reason}}), do: {:error, reason}

  defp update_attrs({:ok, amount}) do
    %{
      currency: Money.round(amount, currency_digits: 2),
      balance: elem(Money.to_string(amount), 1)
    }
  end
end
