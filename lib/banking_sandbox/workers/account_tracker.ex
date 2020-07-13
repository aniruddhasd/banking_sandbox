defmodule BankingSandbox.Workers.AccountTracker do
  @moduledoc """
      Holds account details and associated transactions, one per account
      Monitors account transactions
  """
  use GenServer, restart: :temporary
  alias BankingSandbox.{Account, Transaction}
  alias BankingSandbox.Utils.Helpers
  alias BankingSandbox.Workers.TransactionExecutor
  @supervisor BankingSandbox.PrimarySupervisor
  @registry BankingSandbox.Registry
  require Logger

  @doc """
      Create a new account reference for a customer using customer name
  """
  def create_account(customer_name) do
    account_details = Account.account_data_seeder(customer_name)

    opts = [
      account: account_details,
      name: {:via, Registry, {@registry, {__MODULE__, account_details.id}}}
    ]

    {:ok, pid} = DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
    TransactionExecutor.add_account(pid)
    {:ok, pid}
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    state = %{
      account: Keyword.fetch!(opts, :account),
      transactions: [],
      status: "ready"
    }

    {:ok, state}
  end

  def handle_call({:get_account}, _, state) do
    {:reply, Map.get(state, :account), state}
  end

  def handle_call({:get_transactions}, _, state) do
    {:reply, Map.get(state, :transactions), state}
  end

  def handle_cast({:transaction}, state) do
    account = Map.get(state, :account)
    transaction_skeleton = Helpers.transaction_skeleton(account.balances)

    with %Transaction{} = transaction <-
           Transaction.make_transaction(transaction_skeleton, account),
         %Account{} = updated_account <- Account.update_balance(state.account, transaction),
         updated_transactions <- Transaction.add_transaction(state.transactions, transaction) do
      BankingSandboxWeb.Endpoint.broadcast("banking", "transaction", %{
        value: 1,
        meta: elem(transaction_skeleton, 0)
      })

      state = %{state | account: updated_account, transactions: updated_transactions}
      {:noreply, state}
    else
      {:error, _} ->
        {:noreply, state}
    end
  end

  @doc """
      Get account ref via account_id
  """
  def get_account_via_account_id(account_id) do
    with [{pid, _}] <- Registry.lookup(@registry, {__MODULE__, account_id}),
         true <- Process.alive?(pid) do
      {:ok, pid}
    else
      false -> {:error, "Account terminated"}
      _ -> {:error, :not_found}
    end
  end

  @doc """
      Get Account Details
  """
  def get_account(account_ref) do
    GenServer.call(account_ref, {:get_account})
  end

  def make_transaction(account_ref) do
    GenServer.cast(account_ref, {:transaction})
  end

  @doc """
      Get Account Transaction Details
  """
  def get_account_transactions(account_ref) do
    GenServer.call(account_ref, {:get_transactions})
  end
end
