use Mix.Config

# Configure the main viewport for the Scenic application
config :play, :viewport, %{
  name: :main_viewport,
  size: {500, 500},
  # default_scene: {Play.Scene.Asteroids, nil},
  default_scene: {Play.Scene.Splash, Play.Scene.Asteroids},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "play"]
    }
  ]
}

config :play, :endpoint, PlayWeb.Endpoint

config :play_web, PlayWeb.Endpoint,
  url: [host: "localhost"],
  reloadable_apps: [:play, :play_ui, :play_web],
  server: true,
  secret_key_base: "4m4EdLqbm138oXxQyvWMUy8CEiksqoNBPjoHZEwvhnGVML9SrFNCXtE57z6x8EV1",
  render_errors: [view: PlayWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PlayWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Disable tzdata automatic updates
config :tzdata, :autoupdate, :disabled

config :logger, :console, format: "$time $metadata[$level] $levelpad$message\n"

case Mix.env() do
  :dev ->
    config :exsync,
      reload_timeout: 75,
      reload_callback: {GenServer, :call, [ScenicLiveReload, :reload_current_scene]}

  _ ->
    nil
end

case Mix.env() do
  :dev ->
    config :play_web, PlayWeb.Endpoint,
      http: [port: 4000],
      debug_errors: true,
      code_reloader: true,
      check_origin: false,
      watchers: [
        node: [
          "node_modules/webpack/bin/webpack.js",
          "--mode",
          "development",
          "--watch-stdin",
          cd: Path.expand("../../play_web/assets", __DIR__)
        ]
      ]

    config :play_web, PlayWeb.Endpoint,
      live_reload: [
        patterns: [
          # TODO: Update these paths
          ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
          ~r"priv/gettext/.*(po)$",
          ~r"lib/play_web/{live,views}/.*(ex)$",
          ~r"lib/play_web/templates/.*(eex)$"
        ]
      ]

    config :phoenix_live_reload, dirs: ["../play_web"]

  _ ->
    nil
end
