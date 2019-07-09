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
      exsync_dep(:path),
      {:launcher, path: "../../launcher"},
      {:play, path: "../play"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:scenic_live_reload, path: "../scenic_live_reload"},
      {:timer, path: "../../pomodoro/timer"}
    ]
  end

  defp exsync_dep(:hex), do: {:exsync, "~> 0.2", only: :dev}
  defp exsync_dep(:github), do: {:exsync, github: "falood/exsync", only: :dev}
  defp exsync_dep(:path), do: {:exsync, path: "../../forks/exsync", only: :dev}
end
