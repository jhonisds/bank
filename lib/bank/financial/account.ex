defmodule Bank.Financial.Account do
  @moduledoc """
  Moodule schema `Account`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field(:account_owner, :string)
    field(:balance, :string, default: "00.00")
    field(:currency, Money.Ecto.Composite.Type, default: Money.new!(0, :BRL))

    timestamps()
  end

  def changeset(account, attrs \\ %{}) do
    account
    |> cast(attrs, [:account_owner, :balance, :currency])
    |> validate_required([:account_owner])
    |> unique_constraint(:account_owner)
  end
end
