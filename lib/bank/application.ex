defmodule Bank.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the service which maintains the
      # :ets table that holds the private use currencies
      Cldr.Currency,

      # Start the Ecto repository
      Bank.Repo,
      # Start the Telemetry supervisor
      BankWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Bank.PubSub},
      # Start the Endpoint (http/https)
      BankWeb.Endpoint

      # Start a worker by calling: Bank.Worker.start_link(arg)
      # {Bank.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BankWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
