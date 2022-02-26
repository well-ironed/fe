defmodule FE.MixProject do
  use Mix.Project

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
      version: "0.1.4"
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
      links: %{"GitHub" => "https://github.com/well-ironed/fe"}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5.1", only: :test, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
