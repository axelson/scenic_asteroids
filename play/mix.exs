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
        plt_add_deps: :transitive, plt_add_apps: [:mix, :iex],
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
      {:elixir_make, "~> 0.4"},
      {:scenic, "~> 0.9.0"},
      {:sched_ex, "~> 1.0.2"},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
    ]
  end
end
