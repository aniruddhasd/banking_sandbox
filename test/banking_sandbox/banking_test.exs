defmodule BankingSandbox.BankingTest do
  use ExUnit.Case

  alias BankingSandbox.{Banking, BankServer}
  alias BankingSandbox.{Account, Transaction}
  alias BankingSandbox.Workers.{CustomerTracker, AccountTracker}
  alias BankingSandbox.Utils.Helpers
  require Logger

  describe "accounts" do
    @valid_customer_attrs %{name: Helpers.generate_name()}
    @invalid_customer_attrs %{name: nil}

    test "create account for a customer with valid data" do
      account_details = Account.account_data_seeder(@valid_customer_attrs.name)
      assert @valid_customer_attrs.name == account_details.name
    end

    test "create account for a customer with invalid data" do
      assert_raise RuntimeError, fn ->
        Account.account_data_seeder(@invalid_customer_attrs.name)
      end
    end
  end

  describe "transactions" do
    @valid_customer_attrs %{name: Helpers.generate_name()}

    setup do
      account = Account.account_data_seeder(@valid_customer_attrs.name)
      {:ok, account: account}
    end

    test "create transaction for a valid account", %{account: account} do
      transaction_skeleton = Helpers.transaction_skeleton(account.balances)
      transaction = Transaction.make_transaction(transaction_skeleton, account)

      assert elem(transaction_skeleton, 1) == transaction.type
      assert elem(transaction_skeleton, 2) == abs(transaction.amount)
      assert elem(transaction_skeleton, 3) == transaction.date
    end

    test "always create credit transaction when account balance is 0", %{account: account} do
      account = Map.put(account, :balances, %{available: 0, ledger: 0})
      transaction_skeleton = Helpers.transaction_skeleton(account.balances)

      assert elem(transaction_skeleton, 0) == :credit
    end

    test "amount is debitted when transaction meta is :debit", %{account: account} do
      transaction_skeleton = {:debit, "tax", 14.56, "2020-06-23"}
      transaction = Transaction.make_transaction(transaction_skeleton, account)

      assert account.balances.available > transaction.running_balance
      assert 0 > transaction.amount
    end

    test "amount is creditted when transaction meta is :credit", %{account: account} do
      transaction_skeleton = {:credit, "Interest", 22.66, "2020-06-23"}
      transaction = Transaction.make_transaction(transaction_skeleton, account)

      assert account.balances.available < transaction.running_balance
      assert 0 < transaction.amount
    end
  end

  describe "Banking" do
    setup do
      token = Helpers.generate_access_token()
      {:ok, customer_ref} = CustomerTracker.create_customer(token)
      {:ok, customer_ref: customer_ref, token: token}
    end

    test "Creation of customer" do
      token = Helpers.generate_access_token()

      customer_ref =
        case CustomerTracker.create_customer(token) do
          {:ok, customer_ref} -> customer_ref
          _ -> nil
        end

      assert true == Process.alive?(customer_ref)
    end

    test "Validated customer by fetching via token", %{customer_ref: customer_ref, token: token} do
      {:ok, customer_ref_via_token} = CustomerTracker.get_customer_via_token(token)
      assert customer_ref_via_token == customer_ref
    end

    test "Validated customer default account is setup during creation", %{
      customer_ref: customer_ref
    } do
      [hd | _tail] = CustomerTracker.get_customer_accounts(customer_ref)
      assert true == !is_nil(hd)
    end

    test "Validate customer details in default account, setup during creation", %{
      customer_ref: customer_ref
    } do
      [hd | _tail] = CustomerTracker.get_customer_accounts(customer_ref)
      account = AccountTracker.get_account(hd)
      customer = CustomerTracker.get_customer(customer_ref)
      assert account.name == customer.customer_name
    end

    test "Add new accounts to customer", %{customer_ref: customer_ref} do
      accounts = CustomerTracker.get_customer_accounts(customer_ref)
      CustomerTracker.add_account_to_customer(customer_ref)
      updated_accounts = CustomerTracker.get_customer_accounts(customer_ref)
      assert length(accounts) < length(updated_accounts)
    end

    test "List all account with details of customer", %{customer_ref: customer_ref, token: token} do
      CustomerTracker.add_account_to_customer(customer_ref)
      CustomerTracker.add_account_to_customer(customer_ref)
      {:ok, [hd | _tail]} = Banking.get_customer_accounts(token)
      account_refs = CustomerTracker.get_customer_accounts(customer_ref)

      accounts_via_refs =
        Enum.map(account_refs, fn account_ref ->
          AccountTracker.get_account(account_ref)
        end)

      assert hd in accounts_via_refs
    end

    test "Get token list from bank_server, pick one to view a customer's accounts" do
      token = BankServer.get_token_list() |> Helpers.generate_random(1)
      {:ok, accounts} = Banking.get_customer_accounts(token)
      Process.sleep(3000)
      assert true == is_list(accounts)
    end

    test "remove dead account from customer list & tracking list when it fails due to some reason",
         %{customer_ref: customer_ref} do
      [account_ref | _tail] = CustomerTracker.get_customer_accounts(customer_ref)

      try do
        GenServer.call(account_ref, :random_request)
      catch
        :exit, _ ->
          IO.puts("Crashing Server for Testing, caught expection from crashing test process")
      end

      assert true == Process.alive?(customer_ref)
      updated_accounts = CustomerTracker.get_customer_accounts(customer_ref)
      assert true == account_ref not in updated_accounts
    end

    test "remove token associated with a customer who has crashed for some reason" do
      token = BankServer.get_token_list() |> Helpers.generate_random(1)
      {:ok, customer_ref_via_token} = CustomerTracker.get_customer_via_token(token)
      assert true == Process.alive?(customer_ref_via_token)

      try do
        GenServer.call(customer_ref_via_token, :random_request)
      catch
        :exit, _ ->
          IO.puts("Crashing Server for Testing, caught expection from crashing test process")
      end

      assert true != Process.alive?(customer_ref_via_token)
      assert true == token not in BankServer.get_token_list()
    end
  end
end
