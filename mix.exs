defmodule VisitedServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :visited_server,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :app_tree,
        plt_add_apps: [:poison]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:redis_poolex],
      extra_applications: [:logger, :plug_cowboy],
      mod: {VisitedServer.Application, []}

    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:redis_poolex, "~> 0.0.5"},
      {:dialyxir, "~> 0.4", only: [:dev]}
    ]
  end
end
