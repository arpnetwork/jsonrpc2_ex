defmodule JSONRPC2.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonrpc2,
      version: "0.2.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
