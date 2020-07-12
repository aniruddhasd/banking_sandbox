defmodule BankingSandboxWeb.PageLive do
  use BankingSandboxWeb, :live_view
    require Logger  
    alias BankingSandbox.BankServer
    def mount(_params, _session, socket) do
      BankingSandboxWeb.Endpoint.subscribe("banking")
      %{accounts: accounts, transactions: transactions, customers: customers} = BankServer.get_live_stats()
      socket = socket
                |> assign(:customers, customers)
                |> assign(:accounts, accounts)
                |> assign(:transactions, transactions)
      {:ok, socket}
    end

    def handle_info(%{event: "customer", payload: %{value: value} } = _data, %{assigns: %{customers: customers}} = socket) do
      {:noreply, socket |> assign(customers: customers + value)}
    end

    def handle_info(%{event: "account", payload: %{value: value} } = _data, %{assigns: %{accounts: accounts}} = socket) do
      {:noreply, socket |> assign(accounts: accounts + value)}
    end

    def handle_info(%{event: "transaction", payload: %{value: value} } = _data, %{assigns: %{transactions: transactions}} = socket) do
      {:noreply, socket |> assign(transactions: transactions + value)}
    end    
  
    def render(assigns) do
      ~L"""
      <div>
        <h1>Customers: <%= @customers %></h1>
        <h1>Accounts: <%= @accounts %></h1>
        <h1>Transactions: <%= @transactions %></h1>
      </div>
      """
    end

    
end
