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
      {:launcher, path: "../../launcher"},
      {:play, path: "../play"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      scenic_live_reload_dep(:github),
      {:timer, path: "../../pomodoro/timer"}
    ]
  end

  defp scenic_live_reload_dep(:hex), do: {:scenic_live_reload, "~> 0.1", only: :dev}

  defp scenic_live_reload_dep(:github),
    do: {:scenic_live_reload, github: "axelson/scenic_live_reload", only: :dev}

  defp scenic_live_reload_dep(:path),
    do: {:scenic_live_reload, path: "../../scenic_live_reload", only: :dev}
end
