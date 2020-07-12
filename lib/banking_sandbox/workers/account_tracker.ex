defmodule BankingSandbox.Workers.AccountTracker do

    use GenServer, restart: :temporary
    alias BankingSandbox.{Account, Transaction}
    alias BankingSandbox.Utils.Helpers
    @supervisor BankingSandbox.PrimarySupervisor
    @registry BankingSandbox.Registry
    def create_account(customer_name) do
        account_details = Account.account_data_seeder(customer_name)
        opts = [
          account: account_details,
          name: {:via, Registry, {@registry, {__MODULE__, account_details.id}}}
        ]
    
        DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
    end

    def get_account_via_account_id(account_id) do
        with [{pid, _}]  <- Registry.lookup(@registry, {__MODULE__, account_id}),
                true <- Process.alive?(pid) do
                    {:ok, pid}
        else
            false -> {:error, "Account terminated"}
            _ -> {:error, :not_found}
        end
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

    def handle_call({:get_account},_,state) do
        {:reply,Map.get(state, :account) ,state}
    end
    
    def handle_call({:get_transactions},_,state) do
        {:reply,Map.get(state, :transactions) ,state}
    end    

    def get_account(pid) do
        GenServer.call(pid,{:get_account})
    end

    def get_account_transactions(pid) do
        GenServer.call(pid,{:get_transactions})
    end    

    def handle_cast({:transaction},state) do        
        account = Map.get(state, :account)
        transaction_skeleton = Helpers.transaction_skeleton(account.balances)
        with    %Transaction{} = transaction <- Transaction.make_transaction(transaction_skeleton, account),
                %Account{} = updated_account <- Account.update_balance(state.account,transaction),
                updated_transactions <- Transaction.add_transaction(state.transactions, transaction) do
                BankingSandboxWeb.Endpoint.broadcast("banking", "transaction", %{value: 1})
                state = %{state | account: updated_account, transactions: updated_transactions}
                {:noreply, state}
        else
            {:error,_} ->
                {:noreply, state}
        end
        
    end
end