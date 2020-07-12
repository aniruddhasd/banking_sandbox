defmodule BankingSandbox.BankServer do
    use GenServer
    alias BankingSandbox.Workers.{AccountTracker, CustomerTracker}
    alias BankingSandbox.Utils.Helpers
    require Logger
    def start_link(_) do
        GenServer.start_link(__MODULE__, Map.new(), name: __MODULE__)
    end
    
    def init(state) do                
        state = %{tokens: [], customer_call: 10, account_call: 10000, transaction_call: 1000, accounts: 0, transactions: 0, customers: 0}
        BankingSandboxWeb.Endpoint.subscribe("banking")
        Process.send_after(self(), :customer_call, state.customer_call)        
        {:ok, state}
    end

    def handle_call(:get_token_list, _, state) do
        Logger.info"state #{inspect state}"
        {:reply, Map.get(state, :tokens), state}
    end

    def handle_call(:get_live_stats, _, %{accounts: accounts, transactions: transactions, customers: customers} = state) do
        Logger.info"get_live_stats #{inspect state}"
        {:reply,  %{accounts: accounts, transactions: transactions, customers: customers}, state}
    end

    def handle_info(:customer_call, %{tokens: tokens, customer_call: customer_call} = state) do
        token = Helpers.generate_access_token()
        tokens = case CustomerTracker.create_customer(token) do
            {:ok, customer_ref} -> tokens ++ [token]
            _ -> tokens
        end 
        BankingSandboxWeb.Endpoint.broadcast("banking", "customer", %{value: 1})
        state = %{state | tokens: tokens, customer_call: customer_call * 2}
        Logger.info"info Customer state #{inspect state}"
        Process.send_after(self(), :customer_call, customer_call * 2)
        Process.send_after(self(), :account_call, state.account_call)
        Process.send_after(self(), :transaction_call, state.transaction_call)
        {:noreply, state}
    end

    def handle_info(:account_call, %{tokens: tokens, account_call: account_call} = state) do
        Helpers.generate_random(tokens,1)
        |> CustomerTracker.get_customer()
        |> case do
            {:ok, customer_ref} -> GenServer.cast(customer_ref, {:add_account})
            _ -> nil
        end
        state = %{state | account_call: account_call * 2}
        #Logger.debug"info Account state #{inspect state}"
        Process.send_after(self(), :account_call, account_call * 2)
        {:noreply, state}
    end

    def handle_info(:transaction_call, %{tokens: tokens, transaction_call: transaction_call} = state) do
        with {:ok, customer_ref} <- Helpers.generate_random(tokens,1) |> CustomerTracker.get_customer(),
                accounts = GenServer.call(customer_ref, {:get_customer_accounts}),
                true <- accounts != [],
                account_ref = Helpers.generate_random(accounts,1) do                
                    GenServer.cast(account_ref, {:transaction})
        else    
            {:error, reason} ->
                {:error, reason}
            false ->
                {:error, "No accounts attached to this customer yet"}
        end
        #state = %{state | transaction_call: transaction_call * 1.2 |> trunc}
        #Logger.warn"info Transaction state #{inspect state}"
        Process.send_after(self(), :transaction_call, transaction_call)
        {:noreply, state}
    end    

    def handle_info(%{event: "customer", payload: %{value: value}} = data, %{customers: customers} = state) do
        state = %{state | customers: customers + value}
        {:noreply, state}
    end

    def handle_info(%{event: "account", payload: %{value: value}} = data, %{accounts: accounts} = state) do
        state = %{state | accounts: accounts + value}
        {:noreply, state}
    end
    
    def handle_info(%{event: "transaction", payload: %{value: value}} = data, %{transactions: transactions} = state) do
        state = %{state | transactions: transactions + 1}
        {:noreply, state}
    end    

    def handle_info(data, state) do        
        Logger.info"data here #{inspect data}"
        {:noreply, state}
    end    

    def get_token_list() do
        GenServer.call(__MODULE__,:get_token_list)
    end

    def get_live_stats() do
        GenServer.call(__MODULE__,:get_live_stats)
    end
    
end