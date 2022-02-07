defmodule ArcticClient.Stub do
  alias ArcticClient.UnaryResponseContext

  @doc """
  # ArcticClient.Stub.connect("localhost", 50051, adapter: DemoAdapter)
  """
  def connect(host, port, opts) do
    channel = %ArcticBase.Channel{
      host: host,
      port: port,
      adapter: %ArcticBase.StubAdapter{module: opts[:adapter]},
      stub_module: __MODULE__
    }

    channel.adapter.module.connect(channel)
  end

  @spec unary_request(ArcticBase.Channel.t(), String.t(), ArcticBase.Rpc.t(), struct) ::
          {:ok, struct} | {:error, ArcticBase.RpcError.t()}
  def unary_request(channel, service_name, rpc, request) do
    :ok = ArcticBase.Channel.validate_input(channel)
    :ok = ArcticBase.StubAdapter.validate_input(channel.adapter)

    message = Protobuf.Encoder.encode(request)

    unary_request = ArcticBase.UnaryRequest.create(service_name, rpc, message)

    case channel.adapter.module.request(channel, unary_request) do
      {:ok, response} = ok_resp ->
        # TODO: check done
        with :ok <- validate_status(response),
             :ok <- validate_headers(response) do
          decode_data_to_response(response.data, rpc.response)
        end

      {:error, _} = error ->
        # Unexpcted inter process error
        IO.inspect(error)
        throw(:unary_request)
    end
  end

  defp decode_data_to_response(data, response) do
    # TODO: handle any error?
    message = ArcticBase.Message.from_data(data)
    {:ok, Protobuf.Decoder.decode(message, response)}
  end

  defp validate_status(response) do
    if response.status == 200 do
      :ok
    else
      {:error,
       %ArcticBase.RpcError{
         message: "status got is #{response.status} instead of 200",
         status: ArcticBase.Status.internal()
       }}
    end
  end

  defp validate_headers(response) do
    headers = Map.new(response.headers)

    if headers["grpc-status"] && headers["grpc-status"] != "0" do
      {:error,
       %ArcticBase.RpcError{
         message: headers["grpc-message"],
         status: String.to_integer(headers["grpc-status"])
       }}
    else
      :ok
    end
  end
end
