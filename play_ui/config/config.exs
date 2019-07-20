use Mix.Config

# Configure the main viewport for the Scenic application
config :play, :viewport, %{
  name: :main_viewport,
  size: {500, 500},
  # default_scene: {Timer.Scene.Home, nil},
  # default_scene: {Play.Scene.Asteroids, nil},
  # default_scene: {Play.Scene.Splash, Play.Scene.Asteroids},
  default_scene: {Launcher.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "play"]
    }
  ]
}

# Disable tzdata automatic updates
config :tzdata, :autoupdate, :disabled

case Mix.env() do
  :dev ->
    config :exsync,
      reload_timeout: 75,
      reload_callback: {GenServer, :call, [ScenicLiveReload, :reload_current_scene]}

  _ ->
    nil
end
