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
      dep(:launcher, :github),
      {:play, path: "../play"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      dep(:scenic_live_reload, :github),
      dep(:timer, :github)
    ]
  end

  defp dep(:launcher, :path), do: {:launcher, path: "../../launcher"}
  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}
  defp dep(:timer, :path), do: {:timer, path: "../../pomodoro/timer"}
  defp dep(:timer, :github), do: {:timer, github: "axelson/pomodoro"}

  defp dep(:scenic_live_reload, :hex), do: {:scenic_live_reload, "~> 0.1", only: :dev}

  defp dep(:scenic_live_reload, :github),
    do: {:scenic_live_reload, github: "axelson/scenic_live_reload", only: :dev}

  defp dep(:scenic_live_reload, :path),
    do: {:scenic_live_reload, path: "../../scenic_live_reload", only: :dev}
end
