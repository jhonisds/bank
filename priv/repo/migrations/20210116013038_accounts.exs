defmodule Bank.Repo.Migrations.Accounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :account_owner, :string
      add :balance, :string
      add :currency, :money_with_currency

      timestamps()
    end

    create unique_index(:accounts, [:account_owner])
  end
end
