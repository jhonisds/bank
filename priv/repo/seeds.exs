# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Bank.Repo.insert!(%Bank.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Bank.Accounts

accounts = [
  %{account_owner: "Tupac", currency: Money.new(:BRL, 0), balance: "R$ 0"},
  %{account_owner: "Notorious", currency: Money.new(:BRL, 500), balance: "R$ 500,55"},
  %{account_owner: "Lauryn", currency: Money.new(:USD, 100), balance: "U$ 100.99"},
  %{account_owner: "Dre", currency: Money.new(:EUR, 200), balance: "€ 200.05"},
  %{account_owner: "Snoop", currency: Money.new(:AUD, 300), balance: "AU$ 300,00"}
]

Enum.each(accounts, &Accounts.create_account/1)
