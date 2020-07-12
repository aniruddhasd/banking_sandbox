defmodule BankingSandbox.Account do

    alias BankingSandbox.Utils.Helpers
    alias BankingSandbox.Transaction
  defstruct account_number: "",
            balances: %{available: nil, ledger: nil},
            currency_code: "",
            enrollment_id: "",
            id: "",
            institution: %{
              id: "",
              name: ""
            },
            links: %{
              self: "",
              transactions: ""
            },
            name: "",
            routing_numbers: %{
              ach: "",
              wire: ""
            }

    @doc ~s"""
            Generate data to mimic new account details
    """
    def account_data_seeder(name) do
        id = "test_acc_"<>Helpers.generate_random_string(6)        
        institution =  Helpers.generate_random([%{name: "One Bank",id: "one_bank"}, %{name: "World Bank", id: "world_bank"}, %{name: "Global Bank", id: "global_bank"}],1)
        %BankingSandbox.Account{
            account_number: Enum.random(1..100000000000) |> Integer.to_string,
            balances: %{available: 500.00 , ledger: 500.00},
            currency_code: Helpers.generate_random(["USD","UKP","EURO","INR"],1),
            enrollment_id: "test_enr_"<>Helpers.generate_random_string(6),
            id: id,
            institution: institution,
            links: %{
              self: "http://localhost/accounts/"<>id,
              transactions: "http://localhost/accounts/"<>id<>"/transactions/"
            },
            name: name,
            routing_numbers: %{
              ach: Enum.random(1..100000000000) |> Integer.to_string,
              wire: Enum.random(1..100000000000) |> Integer.to_string
            }
        }
    end

    def add_account(accounts, account) do
      accounts ++ [account]
    end

    def remove_account(accounts, account) do
      accounts -- [account]
    end

    def update_balance(account, %Transaction{running_balance: running_balance} = _transaction) do
        %{account | balances: %{available: running_balance, ledger: running_balance}}
    end

end
