defmodule BankingSandboxWeb.Router do
  use BankingSandboxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BankingSandboxWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BankingSandboxWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.
  scope "/", BankingSandboxWeb do
    pipe_through :api
    get "/accounts", PageController, :list
    get "/accounts/:account_id", PageController, :show
    get "/accounts/:account_id/transactions", PageController, :show_transactions
    get "/accounts/:account_id/transactions/:transaction_id", PageController, :show_transaction
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: BankingSandboxWeb.Telemetry
    end
  end
end
