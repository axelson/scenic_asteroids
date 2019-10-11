defmodule Play.MixProject do
  use Mix.Project

  def project do
    [
      app: :play,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_env: %{"MIX_ENV" => to_string(Mix.env())},
      make_clean: ["clean"],
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
      mod: {Play, []},
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.0.0-rc.7", only: :dev, runtime: false},
      {:elixir_make, "~> 0.4"},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
      dep(:launcher, :github),
      {:scenic, "~> 0.10"},
      {:sched_ex, "~> 1.1.1"}
    ]
  end

  defp dep(:launcher, :path), do: {:launcher, path: "../../launcher"}
  defp dep(:launcher, :github), do: {:launcher, github: "axelson/scenic_launcher"}
end
