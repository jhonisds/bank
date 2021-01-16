defmodule Bank.Accounts do
  @moduledoc """
  Context for Accounts.
  """
  alias Bank.{Financial.Account, Repo}

  @doc """
  Creates new account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: invalid_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts, do: Repo.all(Account)

  @doc """
  Gests a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(1)
      %Account{}

      iex> get_account!(999)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Updates an account.

  ## Examples

      iex> update_account(id, %{field: value})
      {:ok, %Account{}}

      iex> update_account(id, %{field: new_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(id, attrs) do
    get_account!(id)
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete an account.

  ## Examples

      iex> delete_account(id)
      {:ok, %Account{}}

      iex> delete_account(id)
      {:error, %Ecto.Changeset}

  """
  def delete_account(id), do: Repo.delete(get_account!(id))

  @doc """
  Update multi accounts.

  ## Examples

      iex> update_multi(from, to)
      {:ok, %Account{}}

      iex> update_multi(from, to)
      {:error, %Ecto.Changeset}

  """
  def update_multi(from, to) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:from_account, from)
    |> Ecto.Multi.update(:to_account, to)
    |> Bank.Repo.transaction()
  end
end
