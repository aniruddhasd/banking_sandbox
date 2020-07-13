defmodule BankingSandboxWeb.PageLive do
  use BankingSandboxWeb, :live_view
    require Logger  
    alias BankingSandbox.BankServer
    def mount(_params, _session, socket) do
      BankingSandboxWeb.Endpoint.subscribe("banking")
      %{accounts: accounts, transactions: transactions, customers: customers} = BankServer.get_live_stats()
      tokens = BankServer.get_token_list()
      socket = socket
                |> assign(:customers, customers)
                |> assign(:accounts, accounts)
                |> assign(:transactions, transactions)
                |> assign(:tokens, tokens)
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
      <div class="main-container">
      <div class="sub-container">
        <div>
            <h1>
                Live Bank Server
            </h1>
        </div>
        <h2>Customers: <%= @customers %></h2>
        <h2>Accounts: <%= @accounts %></h2>
        <h2>Transactions: <%= @transactions %></h2>
      </div>
      <div class="sub-container">
      <div>
          <h1>
              Tokens
          </h1>
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
