defmodule BankingSandbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BankingSandboxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BankingSandbox.PubSub},
      # Start the Endpoint (http/https)
      BankingSandboxWeb.Endpoint,
      {Registry, keys: :unique, name: BankingSandbox.Registry},
      {DynamicSupervisor, name: BankingSandbox.PrimarySupervisor, strategy: :one_for_one},
      BankingSandbox.BankServer
      # Start a worker by calling: BankingSandbox.Worker.start_link(arg)
      # {BankingSandbox.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BankingSandbox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BankingSandboxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
