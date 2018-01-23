defmodule Pair2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pair2,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:timex, "~> 3.1"}, # date/time functions
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:flow, "~> 0.11"},
    ]
  end
end
