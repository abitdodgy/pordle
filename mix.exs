defmodule Pordle.MixProject do
  use Mix.Project

  def project do
    [
      app: :pordle,
      version: "0.1.0",
      elixir: "~> 1.13",
      escript: escript_config(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Pordle.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      # {:crypto_rand, "~> 1.0"}
    ]
  end

  defp escript_config do
    [main_module: Pordle.CLI]
  end
end
