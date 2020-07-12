defmodule BankingSandbox.Workers.CustomerTracker do
    require Logger    
    use GenServer
    alias BankingSandbox.Utils.Helpers
    alias BankingSandbox.Workers.AccountTracker
    alias BankingSandbox.Account
    @supervisor BankingSandbox.PrimarySupervisor
    @registry BankingSandbox.Registry
    def create_customer() do
        token = Helpers.generate_access_token()
        opts = [
            customer_name: Helpers.generate_name(),
            token: token,
            name: {:via, Registry, {@registry, {__MODULE__, token}}}
        ]
    
        DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
    end

    def create_customer(token) do
        opts = [
            customer_name: Helpers.generate_name(),
            token: token,
            name: {:via, Registry, {@registry, {__MODULE__, token}}}
        ]
    
        DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
    end
    def get_customer(token) do
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
    {:ok, state, {:continue, :default_account}}
    end

    def handle_continue(:default_account, %{accounts: accounts, customer_name: customer_name} = state) do        
        state = add_account(customer_name, accounts, state)
        {:noreply, state}
    end

    def handle_call({:get_customer},_,state) do
        {:reply, state, state}
    end

    def handle_call({:get_customer_accounts},_,state) do
        {:reply,Map.get(state, :accounts) ,state}
    end

    def handle_call({:get_customer_accounts_details},_,%{accounts: accounts} = state) do
        {:reply, accounts, state}
    end
    
    def handle_cast({:add_account},%{accounts: accounts, customer_name: customer_name} = state) do        
        state = add_account(customer_name, accounts, state)
        {:noreply, state}
    end

    def get_cutomer_accounts(pid) do
        GenServer.call(pid,{:get_customer_accounts})
    end

    def add_account(customer_name, accounts, state) do
        with    {:ok, account} <- AccountTracker.create_account(customer_name),
                updated_accounts = Account.add_account(accounts, account) do
                Process.monitor(account)
                BankingSandboxWeb.Endpoint.broadcast("banking", "account", %{value: 1})
                %{state | accounts: updated_accounts}
        else
            {:error,_} ->
                state
        end
    end

    def handle_info({:DOWN, _, :process, account_pid,  _reason} = data, %{accounts: accounts} = state) do
        updated_accounts = Account.remove_account(accounts, account_pid)
        state = %{state | accounts: updated_accounts}
        BankingSandboxWeb.Endpoint.broadcast("banking", "account", %{value: -1})
        {:noreply, state}
    end 

end