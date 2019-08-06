# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Authorize the device to receive firmware using your public key.
# See https://hexdocs.pm/nerves_firmware_ssh/readme.html for more information
# on configuring nerves_firmware_ssh.

key_paths =
  [
    ".ssh/id_rsa.pub",
    ".ssh/id_desktop_rsa.pub",
    ".ssh/id_laptop_rsa.pub"
  ]
  |> Enum.map(fn path -> Path.join(System.user_home!(), path) end)

authorized_keys =
  key_paths
  |> Enum.filter(&File.exists?/1)
  |> Enum.map(&File.read!/1)

if Enum.empty?(authorized_keys),
  do: Mix.raise("No SSH Keys found. Please generate an ssh key")

config :nerves_firmware_ssh,
  authorized_keys: authorized_keys

# Configure nerves_init_gadget.
# See https://hexdocs.pm/nerves_init_gadget/readme.html for more information.

config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcp,
  node_name: "murphy"

config :launcher, :backlight_module, Fw.Backlight
config :launcher, :reboot_mfa, {Nerves.Runtime, :reboot, []}

config :play_web, PlayWeb.Endpoint,
  url: [host: "192.168.1.6"],
  http: [port: 80],
  server: true,
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "GMpxfjaCxeYki1QoUaK2ghoaSZFqaU4Q58AcnbeRQ3o+beajaYQICYtqv9BGUM/1",
  render_errors: [view: PlayWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PlayWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Cannot write update files to a read-only file system. Plus we don't need
# accurate timezones
config :tzdata, :autoupdate, :disabled

config :play, :viewport, %{
  size: {800, 480},
  default_scene: {Play.Scene.Splash, Play.Scene.Asteroids},
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    %{
      module: Scenic.Driver.Nerves.Touch,
      opts: [
        device: "FT5406 memory based driver",
        calibration: {{1, 0, 0}, {1, 0, 0}}
      ]
    }
  ]
}

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
