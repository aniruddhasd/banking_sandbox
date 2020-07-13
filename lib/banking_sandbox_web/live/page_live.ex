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

  def render(assigns) do
    ~L"""
    <div class="main-container">
    <div class="sub-container">
      <div class="title">
          Live Bank Server
      </div>
      <div class="content-text">Customers: <%= @customers %></div>
      <div class="content-text">Accounts: <%= @accounts %></div>
      <div class="content-text">Transactions: <%= elem(@transactions,0) + elem(@transactions,1) %>
        <div class="content-sub-text">Credit: <%= elem(@transactions,0) %> </div>
        <div class="content-sub-text">Debit: <%= elem(@transactions,1) %> </div>
        </div>
    </div>
    <div class="sub-container">
    <div class="title">
            Tokens
    </div>
    <div class="token-table"> 
    <ul class="ul-style">
    <%= for token <- @tokens do %>
        <li class="li-style"> <%= token %> </li>
    <% end %>
    </ul>
    </div>
    </div>
    """
  end
end
