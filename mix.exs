defmodule FE.MixProject do
  use Mix.Project

  def project do
    [
      app: :fe,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      preferred_cli_env: [dialyzer: :test],
      description: description(),
      package: package(),
      source_url: "https://github.com/distributed-owls/fe"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp description do
    "Collection of useful data types brought to Elixir from other functional languages."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/distributed-owls/fe"}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5.1", only: :test, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
