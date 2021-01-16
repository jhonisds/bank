defmodule Bank.TestHelpers do
  @moduledoc """
  This module build fixtures functions for accounts.
  """
  alias Bank.Accounts

  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        account_owner: "user #{System.unique_integer([:positive])}",
        balance: "00.00",
        currency: attrs[:currency] || Money.new!(0, :BRL)
      })
      |> Accounts.create_account()

    account
  end
end
