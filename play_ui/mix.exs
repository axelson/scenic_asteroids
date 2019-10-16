defmodule PlayUi.MixProject do
  use Mix.Project

  def project do
    [
      app: :play_ui,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        plt_add_deps: :transitive,
        plt_add_apps: [:mix, :iex]
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.0.0-rc.7", only: :dev, runtime: false},
      dep(:phoenix_live_reload, :path),
      dep(:exsync, :hex),
      {:play, path: "../play"},
      {:play_web, path: "../play_web"},
      dep(:launcher, :github),
      # Need master for fix of: https://github.com/boydm/scenic_driver_glfw/issues/25
      # {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:scenic_driver_glfw, github: "boydm/scenic_driver_glfw", override: true, targets: :host},
      dep(:scenic_live_reload, :hex)
    ]
    |> List.flatten()
  end

  defp dep(:exsync, :hex), do: {:exsync, "~> 0.2"}

  defp dep(:exsync, :github),
    do: {:exsync, github: "axelson/exsync", branch: "log-errors-better", override: true}

  defp dep(:exsync, :path), do: {:exsync, path: "../../forks/exsync", override: true}

  defp dep(:launcher, :path), do: {:launcher, path: "../../launcher", override: true}
  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}

  defp dep(:phoenix_live_reload, :path),
    do: {:phoenix_live_reload, path: "../../forks/phoenix_live_reload", only: :dev}

  defp dep(:phoenix_live_reload, :github), do: {:phoenix_live_reload, "~> 1.2", only: :dev}

  defp dep(:scenic_live_reload, :hex), do: {:scenic_live_reload, "~> 0.1", only: :dev}

  defp dep(:scenic_live_reload, :github),
    do: {:scenic_live_reload, github: "axelson/scenic_live_reload", only: :dev}

  defp dep(:scenic_live_reload, :path),
    do: {:scenic_live_reload, path: "../../scenic_live_reload", only: :dev}
end
