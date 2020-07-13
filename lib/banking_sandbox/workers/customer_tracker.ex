defmodule BankingSandbox.Workers.CustomerTracker do
  @moduledoc """
      Holds customer details and associated account refs, one per customer
      Monitors customer accounts
  """
  use GenServer, restart: :temporary
  alias BankingSandbox.Utils.Helpers
  alias BankingSandbox.Workers.{AccountTracker, TransactionExecutor}
  alias BankingSandbox.Account
  @supervisor BankingSandbox.PrimarySupervisor
  @registry BankingSandbox.Registry
  require Logger

  def create_customer(token) do
    opts = [
      customer_name: Helpers.generate_name(),
      token: token,
      name: {:via, Registry, {@registry, {__MODULE__, token}}}
    ]

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    state = %{
      customer_name: Keyword.fetch!(opts, :customer_name),
      token: Keyword.fetch!(opts, :token),
      accounts: []
    }

    Process.flag(:trap_exit, true)
    {:ok, state, {:continue, :default_account}}
  end

  def handle_continue(
        :default_account,
        %{accounts: accounts, customer_name: customer_name} = state
      ) do
    updated_accounts = add_account(customer_name, accounts)
    state = %{state | accounts: updated_accounts}
    {:noreply, state}
  end

  def handle_call({:get_customer}, _, state) do
    {:reply, state, state}
  end

  def handle_call({:get_customer_accounts}, _, state) do
    {:reply, Map.get(state, :accounts), state}
  end

  def handle_cast({:add_account}, %{accounts: accounts, customer_name: customer_name} = state) do
    updated_accounts = add_account(customer_name, accounts)
    state = %{state | accounts: updated_accounts}
    {:noreply, state}
  end

  def handle_info(
        {:DOWN, _, :process, account_pid, _reason} = _data,
        %{accounts: accounts} = state
      ) do
    updated_accounts = Account.remove_account(accounts, account_pid)
    state = %{state | accounts: updated_accounts}
    TransactionExecutor.remove_account(account_pid)
    BankingSandboxWeb.Endpoint.broadcast("banking", "account", %{value: -1})
    {:noreply, state}
  end

  def terminate(_reason, %{token: token} = _state) do
    Process.send(BankingSandbox.BankServer, {:remove_token, token}, [])
  end

  @doc """
      Add a new account to the customer
      Monitor it        
  """
  def add_account(customer_name, accounts) do
    with {:ok, account} <- AccountTracker.create_account(customer_name),
         updated_accounts = Account.add_account(accounts, account) do
      Process.monitor(account)
      BankingSandboxWeb.Endpoint.broadcast("banking", "account", %{value: 1})
      updated_accounts
    else
      {:error, _} ->
        accounts
    end
  end

  @doc """
      Get customer ref via token
  """
  def get_customer_via_token(token) do
    with [{pid, _}] <- Registry.lookup(@registry, {__MODULE__, token}),
         true <- Process.alive?(pid) do
      {:ok, pid}
    else
      false -> {:error, "Customer no longer associated with the bank"}
      _ -> {:error, :not_found}
    end
  end

  @doc """
      Get customer account refs
  """
  def get_customer_accounts(customer_ref) do
    GenServer.call(customer_ref, {:get_customer_accounts})
  end

  @doc """
      Get customer details
  """
  def get_customer(customer_ref) do
    GenServer.call(customer_ref, {:get_customer})
  end

  @doc """
      Add new account to customer
  """
  def add_account_to_customer(customer_ref) do
    GenServer.cast(customer_ref, {:add_account})
  end
end
