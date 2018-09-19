defmodule JSONRPC2.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonrpc2,
      version: "0.2.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "JSON-RPC 2.0 for Elixir.",
      package: [
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/arpnetwork/jsonrpc2_ex"}
      ]
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
      {:poison, "~> 3.1"},
      {:plug, "~> 1.6"},
      {:hackney, "~> 1.13"}
    ]
  end
end
