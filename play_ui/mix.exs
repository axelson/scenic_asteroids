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
      {:dialyxir, "1.0.0-rc.6", only: :dev, runtime: false},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:play, path: "../play"},
      {:play_web, path: "../play_web"},
      dep(:launcher, :github),
      # {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:scenic_driver_glfw, github: "boydm/scenic_driver_glfw", override: true, targets: :host},
      dep(:scenic_live_reload, :github),
      dep(:timer, :github)
    ]
    |> List.flatten()
  end

  defp dep(:launcher, :path), do: {:launcher, path: "../../launcher", override: true}
  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}

  defp dep(:timer, :path), do: {:timer, path: "../../pomodoro/timer"}

  # Use two sparse deps to same repository to work around:
  # https://groups.google.com/forum/#!topic/elixir-lang-core/cSjjCLcr-YQ
  # NOTE: Ensure that they both reference the same commit
  defp dep(:timer, :github) do
    [
      {:timer, git: "https://github.com/axelson/pomodoro.git", sparse: "timer"},
      {:timer_core,
       git: "https://github.com/axelson/pomodoro.git", sparse: "timer_core", override: true}
    ]
  end

  defp dep(:scenic_live_reload, :hex), do: {:scenic_live_reload, "~> 0.1", only: :dev}

  defp dep(:scenic_live_reload, :github),
    do: {:scenic_live_reload, github: "axelson/scenic_live_reload", only: :dev}

  defp dep(:scenic_live_reload, :path),
    do: {:scenic_live_reload, path: "../../scenic_live_reload", only: :dev}
end
