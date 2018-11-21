defmodule PlayUi.MixProject do
  use Mix.Project

  def project do
    [
      app: :play_ui,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        plt_add_deps: :transitive, plt_add_apps: [:mix, :iex],
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
      # {:exsync, "~> 0.2", only: :dev},
      # {:exsync, path: "../../forks/exsync"},
      {:exsync, github: "axelson/exsync", branch: "my-full-changes", only: :dev},
      {:scenic_driver_glfw, "~> 0.9"},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:play, path: "../play"},
    ]
  end
end
