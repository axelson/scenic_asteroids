defmodule Fw.MixProject do
  use Mix.Project

  @all_targets [:rpi3]
  @app :fw

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.6",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.target() != :host,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Fw.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false},
      {:launcher, path: "../../launcher"},
      {:nerves, "~> 1.5", runtime: false, targets: @all_targets},
      {:nerves_firmware_ssh, ">= 0.0.0", targets: @all_targets},
      {:nerves_init_gadget, "~> 0.4", targets: @all_targets},
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      # {:nerves_system_custom_rpi3, path: "~/dev/forks/nerves_system_rpi3", runtime: false, targets: :custom_rpi3}
      {:nerves_system_rpi3, "~> 1.8", runtime: false, targets: :rpi3},
      {:play, path: "../play"},
      {:ring_logger, "~> 0.4"},
      {:scenic_driver_nerves_rpi, "0.10.0", targets: @all_targets},
      {:scenic_driver_nerves_touch, "0.10.0", targets: @all_targets},
      {:shoehorn, "~> 0.4"},
      {:timer, path: "../../pomodoro/timer"},
      {:toolshed, "~> 0.2"}
    ]
  end
end
