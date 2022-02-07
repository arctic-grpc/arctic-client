defmodule Helloworld.MixProject do
  use Mix.Project

  def project do
    [
      app: :helloworld,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      {:protobuf, "~> 0.8.0"},
      {:arctic_client, path: "/Users/milad/dev/arctic-grpc/arctic_client"},
      {:arctic_client_mint_adapter,
       path: "/Users/milad/dev/arctic-grpc/arctic_client_mint_adapter"}
    ]
  end
end