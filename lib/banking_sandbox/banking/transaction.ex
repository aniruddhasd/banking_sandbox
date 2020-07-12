defmodule BankingSandbox.Transaction do
    alias BankingSandbox.Utils.Helpers
  defstruct type: "",
            running_balance: nil,
            links: %{
              self: "",
              account: ""
            },
            id: "",
            description: "",
            date: "",
            amount: nil,
            account_id: ""


    def make_transaction({:debit, type, amount, date}, %{balances: %{available: available}} = account) do
        id = "test_txn_"<> Helpers.generate_random_string(6)        
        %BankingSandbox.Transaction{
            type: type,
            running_balance: (available - amount)  |> Float.floor(2),
            links: %{
                self: account.links.transactions<>id,
                account: account.links.self
            },
            id: id,
            description: Helpers.spend_type(),
            date: date,
            amount: (amount * -1),
            account_id: account.id
        }
    end

    def make_transaction({:credit, type, amount, date}, %{balances: %{available: available}} = account) do
        id = "test_txn_"<> Helpers.generate_random_string(6)
        %BankingSandbox.Transaction{
            type: type,
            running_balance: (available + amount)  |> Float.floor(2),
            links: %{
                self: account.links.transactions<>id,
                account: account.links.self
            },
            id: id,
            description: Helpers.deposit_type(),
            date: date,
            amount: amount,
            account_id: account.id
        }
    end    

    def add_transaction(transactions, transaction) do
        transactions ++ [transaction]
    end

end
