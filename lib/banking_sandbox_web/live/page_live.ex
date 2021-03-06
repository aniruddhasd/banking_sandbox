defmodule BankingSandboxWeb.PageLive do
  use BankingSandboxWeb, :live_view
  require Logger
  alias BankingSandbox.BankServer

  def mount(_params, _session, socket) do
    BankingSandboxWeb.Endpoint.subscribe("banking")

    %{accounts: accounts, transactions: transactions, customers: customers} =
      BankServer.get_live_stats()

    tokens = BankServer.get_token_list()

    socket =
      socket
      |> assign(:customers, customers)
      |> assign(:accounts, accounts)
      |> assign(:transactions, transactions)
      |> assign(:tokens, tokens)

    {:ok, socket}
  end

  def handle_info(
        %{event: "customer", payload: %{value: value}} = _data,
        %{assigns: %{customers: customers}} = socket
      ) do
    tokens = BankServer.get_token_list() |> Enum.reverse()
    {:noreply, socket |> assign(customers: customers + value, tokens: tokens)}
  end

  def handle_info(
        %{event: "account", payload: %{value: value}} = _data,
        %{assigns: %{accounts: accounts}} = socket
      ) do
    {:noreply, socket |> assign(accounts: accounts + value)}
  end

  def handle_info(
        %{event: "transaction", payload: %{value: _value, meta: meta}} = _data,
        %{assigns: %{transactions: transactions}} = socket
      ) do
    {credits, debits} = transactions
    transactions = if meta == :credit, do: {credits + 1, debits}, else: {credits, debits + 1}
    {:noreply, socket |> assign(transactions: transactions)}
  end
end
