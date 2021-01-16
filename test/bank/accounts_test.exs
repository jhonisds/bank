defmodule Bank.AccountsTest do
  use Bank.DataCase, async: true

  alias Bank.{Accounts, Financial.Account}

  # doctest Accounts
  setup do
    [
      valid_attrs: %{account_owner: "Jhoni", currency: Money.new(:BRL, 0), balance: "R$ 0"},
      invalid_attrs: %{account_owner: nil, currency: nil, balance: nil}
    ]
  end

  describe "create_accounts/1" do
    test "with valid data creates an account", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{id: _id} = account} = Accounts.create_account(valid_attrs)
      assert account.currency == Money.new(:BRL, 0)
      assert account.balance == "R$ 0"
      assert [%Account{id: _ˆid}] = Accounts.list_accounts()
    end

    test "with invalid data returns error changeset",
         %{invalid_attrs: invalid_attrs} do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(invalid_attrs)
      assert Accounts.list_accounts() == []
    end

    test "enforces unique account owner", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{id: _id}} = Accounts.create_account(valid_attrs)
      assert {:error, changeset} = Accounts.create_account(valid_attrs)
      assert %{account_owner: ["has already been taken"]} = errors_on(changeset)
      assert [%Account{id: _ˆid}] = Accounts.list_accounts()
    end
  end

  describe "list_accounts/0" do
    test "returns all accounts" do
      %Account{id: id1} = account_fixture()
      assert [%Account{id: ^id1}] = Accounts.list_accounts()

      %Account{id: id2} = account_fixture()
      assert [%Account{id: ^id1}, %Account{id: ^id2}] = Accounts.list_accounts()
    end

    test "returns an empty list" do
      assert Accounts.list_accounts() == []
    end
  end

  describe "get_account!/1 " do
    test "returns the account with given id" do
      %Account{id: id} = account_fixture()
      assert %Account{id: ^id} = Accounts.get_account!(id)
    end
  end

  describe "update_account!/1 " do
    test "with valid data updates the account" do
      account = account_fixture()

      assert {:ok, account} =
               Accounts.update_account(account.id, %{
                 balance: "R$ 100.99"
               })

      assert %Account{} = account
      assert account.balance == "R$ 100.99"
    end

    test "with invalid data returns error changeset", %{invalid_attrs: invalid_attrs} do
      %Account{id: id} = account = account_fixture()

      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account.id, invalid_attrs)
      assert %Account{id: ^id} = Accounts.get_account!(id)
    end
  end

  describe "delete_account/1" do
    test "deletes the account" do
      account = account_fixture
      assert {:ok, %Account{}} = Accounts.delete_account(account.id)
      assert Accounts.list_accounts() == []
    end
  end
end
