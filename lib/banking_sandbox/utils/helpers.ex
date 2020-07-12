defmodule BankingSandbox.Utils.Helpers do
    require Logger
    alias BankingSandbox.Utils.Constants
    @epoch Constants.epoch
    @spend_types Constants.spend_types
    @first_names Constants.first_names
    @last_names Constants.last_names
    @deposit_types Constants.deposit_types
    @transaction_types_debit Constants.transaction_types_debit
    @transaction_types_credit Constants.transaction_types_credit
    def generate_random(data,pick = 1) do
        Enum.take_random(data, pick) |> hd
    end

    def generate_random(data,pick) do
        Enum.take_random(data, pick)
    end

    def generate_random_string(length) do
        #:crypto.strong_rand_bytes(length) |> Base.encode64 |> binary_part(0, length)
        permalink(length)
    end

    @spec permalink(integer) :: binary
    def permalink(bytes_count) do
        bytes_count
        |> :crypto.strong_rand_bytes()
        |> Base.url_encode64(padding: false)
    end


    def generate_access_token() do
        generate_random_string(16)
    end

    def generate_name() do
        name = Enum.take_random(@first_names,1) ++ Enum.take_random(@last_names,1)
                |>Enum.join(" ")    
    end

    def spend_type() do
        generate_random(@spend_types,1)
    end

    def deposit_type() do
        generate_random(@deposit_types,1)
    end    

    def transaction_skeleton(%{available: available} = _balances) do
        balance = available |> trunc
        transaction_meta = generate_transaction_meta(balance)
        type = generate_transaction_type(transaction_meta)
        amount = generate_transaction_amount(transaction_meta, balance)
        date = generate_transaction_date()
        {transaction_meta, type, amount, date}
    end

    def generate_transaction_meta(balance) when balance > 0 do
        generate_random([:debit, :credit],1)
    end

    def generate_transaction_meta(balance) do
        :credit
    end    

    def generate_transaction_type(:debit) do
        generate_random(@transaction_types_debit,1)
    end

    def generate_transaction_type(:credit) do
        generate_random(@transaction_types_credit, 1)
    end

    def generate_transaction_amount(:debit, balance) do
        generate_random(1..balance,1)/3 |> Float.floor(2)
    end

    def generate_transaction_amount(:credit, balance) when balance > 0 do        
        generate_random(1..(2 * balance),1)/3 |> Float.floor(2)
    end

    def generate_transaction_amount(:credit, balance) do
        500.0
    end

    def generate_transaction_date() do
        delta = ((DateTime.utc_now |> DateTime.to_unix) - @epoch.unix_time) |> div(10)
        Date.add(@epoch.date, delta) |> Date.to_string        
    end

    def read do
        Logger.info"#{inspect @epoch}"
    end
end