defmodule BankingSandboxWeb.PageController do
  use BankingSandboxWeb, :controller
  alias BankingSandbox.Banking
  require Logger

  @doc """
    List out all the accounts for a customer with a valid token
  """
  def list(conn, _params) do
    token = conn |> Plug.Conn.get_req_header("authorization") |> hd

    with {:ok, accounts} <- Banking.get_customer_accounts(token) do
      conn
      |> put_status(:ok)
      |> put_view(BankingSandboxWeb.AccountView)
      |> render("accounts.json", accounts: accounts)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(BankingSandboxWeb.AccountView)
        |> render("error.json", error: reason)
    end
  end

  @doc """
    Fetch account info for a customer with a valid token and account id
  """
  def show(conn, %{"account_id" => account_id} = _params) do
    token = conn |> Plug.Conn.get_req_header("authorization") |> hd

    with {:ok, account} <- Banking.get_customer_account(token, account_id) do
      conn
      |> put_status(:ok)
      |> put_view(BankingSandboxWeb.AccountView)
      |> render("account.json", account: account)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(BankingSandboxWeb.AccountView)
        |> render("error.json", error: reason)
    end
  end

  @doc """
    Fetch transactions for a customer with a valid token and account id
  """
  def show_transactions(conn, %{"account_id" => account_id} = _params) do
    token = conn |> Plug.Conn.get_req_header("authorization") |> hd

    with {:ok, transactions} <- Banking.get_customer_account_transactions(token, account_id) do
      conn
      |> put_status(:ok)
      |> put_view(BankingSandboxWeb.TransactionView)
      |> render("transactions.json", transactions: transactions)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(BankingSandboxWeb.TransactionView)
        |> render("error.json", error: reason)
    end
  end

  @doc """
    Fetch transaction for a customer with a valid token, account id and transaction id
  """
  def show_transaction(
        conn,
        %{"account_id" => account_id, "transaction_id" => transaction_id} = _params
      ) do
    token = conn |> Plug.Conn.get_req_header("authorization") |> hd

    with {:ok, transaction} <-
           Banking.get_customer_account_transaction(token, account_id, transaction_id) do
      conn
      |> put_status(:ok)
      |> put_view(BankingSandboxWeb.TransactionView)
      |> render("transaction.json", transaction: transaction)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(BankingSandboxWeb.TransactionView)
        |> render("error.json", error: reason)
    end
  end
end
