defmodule BankingSandbox.Workers.TransactionExecutor do
  @moduledoc """
      Manage triggering transactions
      Track accounts <creation & closing>, and randomly pick from the list to trigger a transaction
  """
  require Logger
  use GenServer
  alias BankingSandbox.Utils.Helpers
  alias BankingSandbox.Workers.AccountTracker
  @supervisor BankingSandbox.PrimarySupervisor

  def start() do
    DynamicSupervisor.start_child(@supervisor, {__MODULE__, []})
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, Map.new(), name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{account_refs: []}}
  end

  def handle_cast({:new_account, account_ref}, %{account_refs: account_refs} = state) do
    update_account_refs = account_refs ++ [account_ref]
    state = %{state | account_refs: update_account_refs}
    {:noreply, state}
  end

  def handle_cast({:remove_account, account_ref}, %{account_refs: account_refs} = state) do
    update_account_refs = account_refs -- [account_ref]
    state = %{state | account_refs: update_account_refs}
    {:noreply, state}
  end

  def handle_info({:transaction_call, transaction_call}, %{account_refs: account_refs} = state) do
    account_refs = Helpers.generate_random(account_refs, 3)

    Enum.each(account_refs, fn account_ref ->
      AccountTracker.make_transaction(account_ref)
    end)

    # account_ref = Helpers.generate_random(account_refs,1)
    # AccountTracker.make_transaction(account_ref)

    Process.send_after(self(), {:transaction_call, transaction_call}, transaction_call)

    {:noreply, state}
  end

  @doc """
      Add account ref to tracking list on creation
  """
  def add_account(account_ref) do
    GenServer.cast(__MODULE__, {:new_account, account_ref})
  end

  @doc """
      Remove account ref from tracking list when closed/died
  """
  def remove_account(account_ref) do
    GenServer.cast(__MODULE__, {:remove_account, account_ref})
  end
end
