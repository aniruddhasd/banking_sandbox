defmodule BankingSandbox.Banking do

    alias BankingSandbox.Workers.{CustomerTracker, AccountTracker}
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
                account <- AccountTracker.get_account(account_ref) do
                    {:ok, account}
        else
            {:error, reason} ->
                {:error, reason}
        end
        
    end

    def get_customer_account_transactions(token, account_id) do
        with {:ok, account_ref} <- get_customer_account_ref(token, account_id),
                transactions <- AccountTracker.get_account_transactions(account_ref) do
                    {:ok, transactions}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end
        

    def get_customer_account_refs(token) do
        with {:ok, customer_ref} <- CustomerTracker.get_customer_via_token(token),
                account_refs <- CustomerTracker.get_customer_accounts(customer_ref) do                
                {:ok, account_refs}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end

    def get_customer_account_ref(token, account_id) do
        with {:ok, account_refs} <- get_customer_account_refs(token),
                {:ok, account_ref} <- AccountTracker.get_account_via_account_id(account_id),
                true <- account_ref in account_refs do
                    {:ok, account_ref}
        else
            {:error, reason} ->
                {:error, reason}
        end
        
    end

    def get_accounts(account_refs) do
        Enum.map(account_refs, fn account_ref ->
            AccountTracker.get_account(account_ref)
        end)
    end    
end