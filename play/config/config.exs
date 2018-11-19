use Mix.Config

config :play, :viewport, %{
  name: :main_viewport,
  size: {500, 500},
  default_scene: {Play.Scene.Splash, Play.Scene.Asteroids}
}
