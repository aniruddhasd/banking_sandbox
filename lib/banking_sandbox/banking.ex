defmodule BankingSandbox.Banking do

    alias BankingSandbox.Workers.{CustomerTracker, AccountTracker}
    require Logger
    def get_customer_accounts(token) do
        with {:ok, account_refs} <- get_customer_account_refs(token),
            accounts <- get_accounts(account_refs) do
                    {:ok, accounts}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end

    def get_customer_account(token, account_id) do
        with    {:ok, account_ref} <- get_customer_account_ref(token, account_id),
                account <- GenServer.call(account_ref, {:get_account}) do
                    {:ok, account}
        else
            {:error, reason} ->
                {:error, reason}
        end
        
    end

    def get_customer_account_transactions(token, account_id) do
        with {:ok, account_ref} <- get_customer_account_ref(token, account_id),
                transactions <- GenServer.call(account_ref, {:get_transactions}) do
                    {:ok, transactions}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end
        

    def get_customer_account_refs(token) do
        with {:ok, customer_ref} <- CustomerTracker.get_customer(token),
                account_refs <- CustomerTracker.get_cutomer_accounts(customer_ref) do                
                {:ok, account_refs}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end

    def get_customer_account_ref(token, account_id) do
        with {:ok, account_refs} <- get_customer_account_refs(token),
                {:ok, account_ref} <- AccountTracker.get_account(account_id),
                true <- account_ref in account_refs do
                    {:ok, account_ref}
        else
            {:error, reason} ->
                {:error, reason}
        end
        
    end

    def get_accounts(account_refs) do
        Logger.info"account_refs #{inspect account_refs}"
        Enum.map(account_refs, fn account_ref ->
            Logger.info"account_ref #{inspect account_ref}"
            GenServer.call(account_ref, {:get_account})
        end)
    end    
end