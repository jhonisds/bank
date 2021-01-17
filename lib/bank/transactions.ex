defmodule Bank.Transactions do
  @moduledoc """
  Module that provides banking transactions.

  The following transactions are available: `deposit`, `withdraw`, `transfer`, `split` and `exchange`.
  """

  alias Bank.Accounts
  alias Ecto.Changeset

  def deposit(account_id, amount, currency \\ :BRL) do
    amount
    |> is_valid_amount?(account_id, :deposit)
    |> transaction(currency)
  end

  def withdraw(account_id, amount) do
    amount
    |> is_valid_amount?(account_id, :withdraw)
    |> transaction(:BRL)
  end

  def transfer(from_account, to_account, amount) do
    case from_account != to_account do
      true ->
        amount
        |> is_valid_amount?(from_account, :withdraw)
        |> do_transfer(from_account, to_account)

      false ->
        {:error, "Same account. Choose another account to transfer."}
    end
  end

  def split(from_account, accounts, amount) do
    accounts_filter =
      Enum.map(accounts, fn input ->
        Enum.filter(Accounts.list_accounts(), fn account ->
          account.id == input
        end)
      end)

    # value = amount / accounts_filter

    # Enum.map(accounts_filter, &transfer(from_account, &1, value))
  end

  def exchange(from_currency, to_currency, amount) do
    amount
    |> cast()
    |> Money.new(from_currency)
    |> Money.to_currency(to_currency)
    |> case do
      {:ok, currency} ->
        {:ok, "Successfuly exchange: #{Money.to_string(currency) |> elem(1)}"}

      {:error, reason} ->
        reason
    end
  end

  def is_valid_amount?(amount, id, opts) do
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

  def cast(amount) do
    amount
    |> Decimal.cast()
    |> elem(1)
  end

  def has_balance?(amount, account, opts) do
    account.currency
    |> Money.to_decimal()
    |> Decimal.sub(amount)
    |> Decimal.negative?()
    |> case do
      true ->
        {:error, "Sorry, you don't have enought balance. Current balance: #{account.currency}"}

      false ->
        {:ok, %{amount: amount, operation: opts, account: account}}
    end
  end

  def transaction({:ok, attrs}, currency) do
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

  def transaction({:error, reason}, _currency), do: {:error, reason}
  def transaction({:error, {_, reason}}), do: {:error, reason}

  defp get_currency(%Money{amount: _, currency: currency}), do: currency

  def update_balance(attrs, id, opts) do
    case attrs do
      {:error, reason} ->
        {:error, reason}

      changeset ->
        case Accounts.update_account(id, changeset) do
          {:ok, account} ->
            {:ok, "Successfuly #{opts} transaction. Current balance: #{account.balance}"}

          {:error, changeset} ->
            {:error, changeset.errors}
        end
    end
  end

  def operation(amount, account, :deposit) do
    account.currency
    |> Money.add(amount)
    |> update_attrs()
  end

  def operation(amount, account, :withdraw) do
    account.currency
    |> Money.sub(amount)
    |> update_attrs()
  end

  def do_transfer({:error, {_, reason}}), do: {:error, reason}

  def do_transfer({:error, reason}, _, _), do: {:error, reason}

  def do_transfer({:ok, attrs}, from_account, to_account) do
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
         "Successfuly transfer #{amount} to #{to.account_owner}. Current balance: #{
           from_attrs.changes.balance
         }"}

      {:error, :from_account, changeset, _} ->
        {:error, changeset}

      {:error, :to_account, changeset, _} ->
        {:error, changeset}
    end
  rescue
    _e in FunctionClauseError ->
      {:error, "Cannot transfer monies with different currencies."}
  end

  def update_attrs({:error, {_, reason}}), do: {:error, reason}

  def update_attrs({:ok, amount}) do
    %{
      currency: Money.round(amount, currency_digits: 2),
      balance: elem(Money.to_string(amount), 1)
    }
  end
end
