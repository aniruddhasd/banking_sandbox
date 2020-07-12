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

    def handle_info(%{event: "customer", payload: %{value: value} } = data, %{assigns: %{customers: customers}} = socket) do
      Logger.info"live customer #{inspect data}"      
      {:noreply, socket |> assign(customers: customers + value)}
    end

    def handle_info(%{event: "account", payload: %{value: value} } = data, %{assigns: %{accounts: accounts}} = socket) do
      Logger.info"live account #{inspect data}"      
      {:noreply, socket |> assign(accounts: accounts + value)}
    end

    def handle_info(%{event: "transaction", payload: %{value: value} } = data, %{assigns: %{transactions: transactions}} = socket) do
      Logger.info"live transaction #{inspect data}"      
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
