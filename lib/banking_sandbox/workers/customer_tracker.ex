defmodule BankingSandbox.Workers.CustomerTracker do
    
    use GenServer, restart: :temporary
    alias BankingSandbox.Utils.Helpers
    alias BankingSandbox.Workers.AccountTracker
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
    def get_customer_via_token(token) do
        with [{pid, _}]  <- Registry.lookup(@registry, {__MODULE__, token}),
                true <- Process.alive?(pid) do
                    {:ok, pid}
        else
            false -> {:error, "Customer no longer associated with the bank"}
            _ -> {:error, :not_found}
        end
    end

    def start_link(opts) do
        {name, opts} = Keyword.pop(opts, :name)
        GenServer.start_link(__MODULE__, opts, name: name)
    end

    def init(opts) do
    state = %{
        customer_name: Keyword.fetch!(opts, :customer_name),
        token: Keyword.fetch!(opts, :token),
        accounts: [],
    }
    Process.flag(:trap_exit, true)
    {:ok, state, {:continue, :default_account}}
    end

    def handle_continue(:default_account, %{accounts: accounts, customer_name: customer_name} = state) do        
        state = add_account(customer_name, accounts, state)
        Logger.warn"state #{inspect state}"
        Logger.warn"self #{inspect self()}"
        {:noreply, state}
    end

    def handle_call({:get_customer},_,state) do
        {:reply, state, state}
    end

    def handle_call({:get_customer_accounts},_,state) do
        {:reply,Map.get(state, :accounts) ,state}
    end
    
    def handle_cast({:add_account},%{accounts: accounts, customer_name: customer_name} = state) do        
        state = add_account(customer_name, accounts, state)
        {:noreply, state}
    end

    def get_customer_accounts(pid) do
        GenServer.call(pid,{:get_customer_accounts})
    end

    def get_customer(pid) do
        GenServer.call(pid,{:get_customer})
    end

    def add_account(customer_name, accounts, state) do
        with    {:ok, account} <- AccountTracker.create_account(customer_name),
                updated_accounts = Account.add_account(accounts, account) do
                Process.monitor(account)
                #BankingSandboxWeb.Endpoint.broadcast("banking", "account", %{value: 1})
                %{state | accounts: updated_accounts}
        else
            {:error,_} ->
                state
        end
    end

    def handle_info({:DOWN, _, :process, account_pid,  _reason} = _data, %{accounts: accounts} = state) do
        updated_accounts = Account.remove_account(accounts, account_pid)
        state = %{state | accounts: updated_accounts}
        #BankingSandboxWeb.Endpoint.broadcast("banking", "account", %{value: -1})
        {:noreply, state}
    end 

    def terminate(reason, %{token: token} = _state) do
        Process.send(BankingSandbox.BankServer, {:remove_token, token},[])
        Logger.warn"#{__MODULE__}.terminate/2 called with reason: #{inspect reason}"
    end

end