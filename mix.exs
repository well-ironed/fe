defmodule FE.MixProject do
  use Mix.Project

  @version "0.1.5"

  def project do
    [
      app: :fe,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.7",
      package: package(),
      preferred_cli_env: [dialyzer: :test],
      source_url: "https://github.com/well-ironed/fe",
      start_permanent: Mix.env() == :prod,
      version: @version
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
      extras: ["README.md"],
      source_ref: @version,
      source_url: "https://github.com/well-ironed/fe"
    ]
  end

  defp description do
    "Collection of useful data types brought to Elixir from other functional languages."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/well-ironed/fe"}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
