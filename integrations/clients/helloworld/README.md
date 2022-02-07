# Helloworld

**TODO: Add description**

## Steps:

```
protoc -I../../protos --elixir_out=plugins=grpc:./lib helloworld.proto
```
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `helloworld` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:helloworld, "~> 0.1.0"}
  ]
end

{:ok, channel} = ArcticClient.Stub.connect("localhost", 50051, adapter: ArcticClientMintAdapter); Helloworld.Greeter.Stub.say_hello(channel, Helloworld.HelloRequest.new(name: "Hello"))
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/helloworld>.

