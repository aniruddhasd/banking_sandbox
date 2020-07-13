defmodule BankingSandbox.Utils.Helpers do
  alias BankingSandbox.Utils.Constants
  @epoch Constants.epoch()
  @spend_types Constants.spend_types()
  @first_names Constants.first_names()
  @last_names Constants.last_names()
  @deposit_types Constants.deposit_types()
  @transaction_types_debit Constants.transaction_types_debit()
  @transaction_types_credit Constants.transaction_types_credit()
  require Logger

  @doc """
      Pick a single element from a given list randomly
  """
  def generate_random(data, pick = 1) do
    Enum.take_random(data, pick) |> hd
  end

  @doc """
      Pick elements from a given list randomly
  """
  def generate_random(data, pick) do
    Enum.take_random(data, pick)
  end

  @doc """
      Generate random string of given length
  """
  def generate_random_string(length) do
    # :crypto.strong_rand_bytes(length) |> Base.encode64 |> binary_part(0, length)
    permalink(length)
  end

  @doc """
      Generate random binary string of given length
  """
  def permalink(bytes_count) do
    bytes_count
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
      Generate access token
  """
  def generate_access_token() do
    generate_random_string(16)
  end

  @doc """
      Generate name randomly picking first & last names
  """
  def generate_name() do
    (Enum.take_random(@first_names, 1) ++ Enum.take_random(@last_names, 1))
    |> Enum.join(" ")
  end

  @doc """
      Generate random spend type for debit transaction
  """
  def spend_type() do
    generate_random(@spend_types, 1)
  end

  @doc """
      Generate random deposit type for credit transaction
  """
  def deposit_type() do
    generate_random(@deposit_types, 1)
  end

  @doc """
      Generate transaction skeleton based on available balance
  """
  def transaction_skeleton(%{available: available} = _balances) do
    balance = available |> trunc
    transaction_meta = generate_transaction_meta(balance)
    type = generate_transaction_type(transaction_meta)
    amount = generate_transaction_amount(transaction_meta, balance)
    date = generate_transaction_date()
    {transaction_meta, type, amount, date}
  end

  @doc """
      Generate transaction meta based on available balance greater than 0
  """
  def generate_transaction_meta(balance) when balance > 0 do
    generate_random([:debit, :credit], 1)
  end

  @doc """
      Generate transaction meta when account is empty
  """
  def generate_transaction_meta(_balance) do
    :credit
  end

  @doc """
      Generate debit transaction type
  """
  def generate_transaction_type(:debit) do
    generate_random(@transaction_types_debit, 1)
  end

  @doc """
      Generate credit transaction type
  """
  def generate_transaction_type(:credit) do
    generate_random(@transaction_types_credit, 1)
  end

  @doc """
      Generate debit transaction amount based on balance
  """
  def generate_transaction_amount(:debit, balance) do
    (generate_random(1..balance, 1) / 3) |> Float.floor(2)
  end

  @doc """
      Generate credit transaction amount based on balance
  """
  def generate_transaction_amount(:credit, balance) when balance > 0 do
    (generate_random(1..(2 * balance), 1) / 3) |> Float.floor(2)
  end

  @doc """
      Generate credit transaction to refill account
  """
  def generate_transaction_amount(:credit, _balance) do
    500.0
  end

  @doc """
      Generate date of transaction
      Add 1 day to epoch(Jan 1, 2020) every 10s of uptime. #Epoch defined in Constants
      Use current date when generated date reaches current date
  """
  def generate_transaction_date() do
    uptime = :erlang.statistics(:wall_clock) |> elem(0)
    {d, {h, m, s}} = :calendar.seconds_to_daystime(div(uptime, 1000))

    delta =
      cond do
        d > 0 -> d * 86400 + h * 3600 + m * 60 + s
        h > 0 -> h * 3600 + m * 60 + s
        m > 0 -> m * 60 + s
        true -> s
      end
      |> div(10)

    date = Date.add(@epoch.date, delta)

    case Date.compare(date, Date.utc_today()) do
      :lt -> date
      _ -> Date.utc_today()
    end
    |> Date.to_string()
  end
end
