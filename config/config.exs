# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :bank,
  ecto_repos: [Bank.Repo]

# Configures the endpoint
config :bank, BankWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RexJlxcbNfEChQCtwyyGCyDt1SoEgqgr5/Gb2gWHL2xVOwNZrGjHG32nWwxc8nzm",
  render_errors: [view: BankWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Bank.PubSub,
  live_view: [signing_salt: "/ZHj/s6G"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_money,
  exchange_rates_retrieve_every: :never,
  api_module: Money.ExchangeRates.OpenExchangeRates,
  # configure it via environment variable
  # open_exchange_rates_app_id: {:system, "OPEN_EXCHANGE_RATES_APP_ID"}
  open_exchange_rates_app_id: "cc5cb56eb3704b44a4c44c74b24b718a",
  json_library: Jason,
  default_currency: :BRL,
  separator: ".",
  delimiter: ",",
  default_cldr_backend: Bank.Cldr

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
