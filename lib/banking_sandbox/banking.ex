defmodule BankingSandbox.Banking do

    alias BankingSandbox.Workers.{CustomerTracker, AccountTracker}

    @doc """
        List out all the accounts for a customer with a valid token
    """
    def get_customer_accounts(token) do
        with {:ok, account_refs} <- get_customer_account_refs(token),
            accounts <- get_accounts(account_refs) do
                    {:ok, accounts}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end

    @doc """
        Fetch account info for a customer with a valid token and account id
    """
    def get_customer_account(token, account_id) do
        with    {:ok, account_ref} <- get_customer_account_ref(token, account_id),
                account <- AccountTracker.get_account(account_ref) do
                    {:ok, account}
        else
            {:error, reason} ->
                {:error, reason}
        end
        
    end

    @doc """
        Fetch transactions for a customer with a valid token and account id
    """    
    def get_customer_account_transactions(token, account_id) do
        with {:ok, account_ref} <- get_customer_account_ref(token, account_id),
                transactions <- AccountTracker.get_account_transactions(account_ref) do
                    {:ok, transactions}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end

    @doc """
        Fetch transaction for a customer with a valid token, account id and transaction id
    """
    def get_customer_account_transaction(token, account_id, transaction_id) do
        with {:ok, account_ref} <- get_customer_account_ref(token, account_id),
                transactions <- AccountTracker.get_account_transactions(account_ref) do
                    transaction = Enum.find(transactions, fn transaction -> transaction.id == transaction_id end)
                    {:ok, transaction}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end    
        
    @doc """
        Get all account refs for a customer
    """
    def get_customer_account_refs(token) do
        with {:ok, customer_ref} <- CustomerTracker.get_customer_via_token(token),
                account_refs <- CustomerTracker.get_customer_accounts(customer_ref) do                
                {:ok, account_refs}
        else
            {:error, reason} ->
                {:error, reason}
        end
    end

    @doc """
        Get account ref for a customer based on account id
    """
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

    @doc """
        List out full account details for each of the account refs
    """    
    def get_accounts(account_refs) do
        Enum.map(account_refs, fn account_ref ->
            AccountTracker.get_account(account_ref)
        end)
    end    
end