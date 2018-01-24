defmodule Pair2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pair2,
      version: "0.1.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      name: "Pair2",
      source_url: "https://github.com/btedev/pair2",
      description: "Modules for 1:1 reconciliation matching and deduplication",
      package: package()
    ]
  end

  defp package() do
  [
    maintainers: ["barrye@gmail.com"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/btedev/pair2"}
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
      {:timex, "~> 3.1"}, # date/time functions
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:flow, "~> 0.11"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
