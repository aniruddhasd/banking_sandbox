defmodule BankingSandbox.BankServer do
    @moduledoc """
        Manage & monitor customer & account creation
        Maintain customer, account & transaction stats
        Store house for all customer tokens
    """
    use GenServer
    alias BankingSandbox.Workers.{CustomerTracker, TransactionExecutor}
    alias BankingSandbox.Utils.{Helpers, Constants}

    @customer_call_initial Constants.customer_call_initial
    @customer_call_standard_limit Constants.customer_call_standard_limit
    @customer_call_standard Constants.customer_call_standard
    @account_call Constants.account_call
    @transaction_call_standard Constants.transaction_call_standard
    @transaction_call_initial Constants.transaction_call_initial
    require Logger
    def start_link(_) do

        GenServer.start_link(__MODULE__, Map.new(), name: __MODULE__)
    end
    
    def init(_state) do                
        state = %{tokens: [], accounts: 0, transactions: 0, customers: 0}        
        BankingSandboxWeb.Endpoint.subscribe("banking")
        {:ok, state, {:continue, :begin_banking}}
    end

    def handle_continue(:begin_banking, state) do        
        Process.send_after(self(), {:customer_call, @customer_call_initial}, @customer_call_initial)  
        Process.send_after(self(), {:account_call, @account_call}, @account_call)
        Process.send_after(TransactionExecutor, {:transaction_call, @transaction_call_standard}, @transaction_call_initial)
        {:noreply, state}
    end

    def handle_call(:get_token_list, _, state) do
        {:reply, Map.get(state, :tokens), state}
    end

    def handle_call(:get_live_stats, _, %{accounts: accounts, transactions: transactions, customers: customers} = state) do
        {:reply,  %{accounts: accounts, transactions: transactions, customers: customers}, state}
    end

    def handle_info({:customer_call, customer_call}, %{tokens: tokens} = state) do
        token = Helpers.generate_access_token()
        tokens = case CustomerTracker.create_customer(token) do
            {:ok, _customer_ref} -> tokens ++ [token]
            _ -> tokens
        end 
        BankingSandboxWeb.Endpoint.broadcast("banking", "customer", %{value: 1, tokens: tokens})
        customer_call = if length(tokens) < @customer_call_standard_limit, do: customer_call, else: @customer_call_standard
        state = %{state | tokens: tokens}
        Process.send_after(self(), {:customer_call, customer_call}, customer_call)
        {:noreply, state}
    end

    def handle_info({:account_call, account_call}, %{tokens: tokens} = state) do
        Helpers.generate_random(tokens,1)
        |> CustomerTracker.get_customer_via_token()
        |> case do
            {:ok, customer_ref} -> CustomerTracker.add_account_to_customer(customer_ref)
            _ -> nil
        end

        Process.send_after(self(), {:account_call, account_call}, account_call)
        
        {:noreply, state}
    end

    def handle_info({:remove_token, token}, %{tokens: tokens} = state)do
        updated_tokens = tokens -- [token]
        state = %{state | tokens: updated_tokens}

        BankingSandboxWeb.Endpoint.broadcast("banking", "customer", %{value: -1, tokens: updated_tokens})
                
        {:noreply, state}
    end

    def handle_info(%{event: "customer", payload: %{value: value}} = _data, %{customers: customers} = state) do
        state = %{state | customers: customers + value}
        {:noreply, state}
    end

    def handle_info(%{event: "account", payload: %{value: value}} = _data, %{accounts: accounts} = state) do
        state = %{state | accounts: accounts + value}
        {:noreply, state}
    end
    
    def handle_info(%{event: "transaction", payload: %{value: _value}} = _data, %{transactions: transactions} = state) do
        state = %{state | transactions: transactions + 1}
        {:noreply, state}
    end    

    @doc """
        Get List of tokens for all customers of the bank
    """
    def get_token_list() do
        GenServer.call(__MODULE__,:get_token_list)
    end

    @doc """
        Get current banking stats
    """
    def get_live_stats() do
        GenServer.call(__MODULE__,:get_live_stats)
    end
    
end