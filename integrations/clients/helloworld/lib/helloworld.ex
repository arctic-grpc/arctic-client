defmodule Helloworld do
  @moduledoc """
  Documentation for `Helloworld`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Helloworld.hello()
      :world

  """
  def connect do
    {:ok, channel} =
      ArcticClient.Stub.connect(:http, "localhost", 50051, adapter: ArcticClientMintAdapter)

    Helloworld.Greeter.Stub.say_hello(channel, Helloworld.HelloRequest.new(name: "Hello"))
  end

  def connect_with_tls do
    ca_path = Path.expand("./tls/ca.pem", :code.priv_dir(:helloworld))

    {:ok, channel} =
      ArcticClient.Stub.connect(:https, "localhost", 50051,
        adapter: ArcticClientMintAdapter,
        tls_options: [cacertfile: ca_path, verify: :verify_peer]
      )

    Helloworld.Greeter.Stub.say_hello(channel, Helloworld.HelloRequest.new(name: "Hello"))
  end

  def connect_with_tls2 do
    {:ok, channel} =
      ArcticClient.Stub.connect(:https, "wrong.host.badssl.com", 433,
        adapter: ArcticClientMintAdapter
      )

    Helloworld.Greeter.Stub.say_hello(channel, Helloworld.HelloRequest.new(name: "Hello"))
  end
end
