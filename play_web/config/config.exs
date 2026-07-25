# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :play_web, PlayWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4m4EdLqbm138oXxQyvWMUy8CEiksqoNBPjoHZEwvhnGVML9SrFNCXtE57z6x8EV1",
  render_errors: [view: PlayWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: PlayWeb.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.25.0",
  play_web: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  play_web_css: [
    args: ~w(css/app.css --bundle --outdir=../priv/static/css),
    cd: Path.expand("../assets", __DIR__)
  ]

config :tzdata, :autoupdate, :disabled

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
