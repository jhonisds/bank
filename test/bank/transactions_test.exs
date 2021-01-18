defmodule Bank.TransactionsTest do
  use Bank.DataCase, async: true

  alias Bank.{Accounts, Financial.Account, Transactions}
  doctest Transactions

  @attrs %{account_owner: "Jhoni", currency: Money.new(:BRL, 0), balance: "R$ 0"}
  @attrs_has_balance %{
    account_owner: "Notorious",
    currency: Money.new(:BRL, 500),
    balance: "R$ 500,00"
  }
  @attrs_split %{
    account_owner: "Tupac",
    currency: Money.new(:EUR, 600),
    balance: "U$ 600,00"
  }

  setup do
    {:ok, %Account{id: _id} = account} = Accounts.create_account(@attrs)

    [
      account: account
    ]
  end

  describe "deposit/3" do
    test "returns ok when deposit is completed", %{account: account} do
      message = "successfuly deposit transaction - current balance: #{Money.new(100, :BRL)}"
      assert {:ok, message} == Transactions.deposit(account.id, 100)
    end

    test "returns error when account is not found" do
      message = "account: 99 not found"
      assert {:error, message} == Transactions.deposit(99, 100)
    end

    test "returns error when amount is invalid", %{account: account} do
      assert_raise ArgumentError, fn ->
        Transactions.deposit(account.id, -100)
      end
    end

    test "returns error when deposit different currencies", %{account: account} do
      message = "Cannot add monies with different currencies. Received :BRL and :CAD."
      assert {:error, message} == Transactions.deposit(account.id, 100, :CAD)
    end

    test "returns error when currency is invalid", %{account: account} do
      message = "The currency :ERRO is invalid"
      assert {:error, message} == Transactions.deposit(account.id, 100, :ERRO)
    end
  end

  describe "withdraw/2" do
    test "returns ok when withdraw is completed" do
      assert {:ok, %Account{id: _id} = account} = Accounts.create_account(@attrs_has_balance)
      message = "successfuly withdraw transaction - current balance: #{Money.new(400, :BRL)}"
      assert {:ok, message} == Transactions.withdraw(account.id, 100)
    end

    test "returns error when balance is insufficient" do
      assert {:ok, %Account{id: _id} = account} = Accounts.create_account(@attrs_has_balance)
      message = "sorry, you don't have enought balance - current balance: #{Money.new(500, :BRL)}"
      assert {:error, message} == Transactions.withdraw(account.id, 1000)
    end
  end

  describe "transfer/3" do
    test "returns ok when transfer is completed", %{account: account} do
      assert {:ok, %Account{id: _id} = account1} = Accounts.create_account(@attrs_has_balance)

      message =
        "successfuly transfer #{Money.new(100, :BRL)} to Jhoni - current balance: #{
          Money.new(400, :BRL)
        }"

      assert {:ok, message} == Transactions.transfer(account1.id, account.id, 100)
    end

    test "returns error when accounts are equals", %{account: account} do
      message = "same account - choose another account to transfer"
      assert {:error, message} == Transactions.transfer(account.id, account.id, 100)
    end

    test "returns error when account is not found" do
      assert {:ok, %Account{id: _id} = account} = Accounts.create_account(@attrs_has_balance)
      message = "account: 99 not found"
      assert {:error, message} == Transactions.transfer(account.id, 99, 100)
    end
  end

  describe "split/3" do
    test "returns ok when split is completed", %{account: account} do
      assert {:ok, %Account{id: _id} = account1} = Accounts.create_account(@attrs_has_balance)
      assert {:ok, %Account{id: _id} = account2} = Accounts.create_account(@attrs_split)

      expected = [
        {:ok,
         "successfuly transfer #{Money.new(50, :BRL)} to Jhoni - current balance: #{
           Money.new(450, :BRL)
         }"},
        {:error, "cannot transfer monies with different currencies"}
      ]

      accounts = [account.id, account2.id]
      assert Transactions.split(account1.id, accounts, 100) == expected
    end

    test "returns error when currencies are differents", %{account: account} do
      assert {:ok, %Account{id: _id} = account1} = Accounts.create_account(@attrs_split)

      expected = [
        {:error, "cannot transfer monies with different currencies"}
      ]

      accounts = [account.id]
      assert Transactions.split(account1.id, accounts, 100) == expected
    end

    test "returns error when split to the same account", %{account: account} do
      expected = [
        {:error, "same account - choose another account to transfer"}
      ]

      assert Transactions.split(account.id, [account.id], 100) == expected
    end
  end

  describe "exchange/3" do
    test "returns ok when exchange is completed" do
      currency = Money.new("18,89", :USD)

      message = "successfuly exchange: #{currency}"
      assert {:ok, message} == Transactions.exchange(:BRL, :USD, 100)
    end

    test "returns error when currency is invalid" do
      assert {_, "The currency :ERRO is invalid"} = Transactions.exchange(:BRL, :ERRO, 100)
    end

    test "returns error when amount is invalid" do
      assert_raise ArgumentError, fn ->
        Transactions.exchange(:BRL, :USD, -100)
      end
    end
  end
end
