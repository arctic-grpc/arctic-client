defmodule ArcticClient.Stub do
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

  def stream_request(channel, service_name, rpc, request, _opts) do
    :ok = ArcticBase.Channel.validate_input(channel)
    :ok = ArcticBase.StubAdapter.validate_input(channel.adapter)

    caller_pid = self()
    ref = make_ref()

    decoder = fn data ->
      {:stream, response} = rpc.response
      decode_stream_data_to_response(data, response)
    end

    {:ok, stream_reader_pid} =
      ArcticClient.Stub.StreamReader.start_link([caller_pid, ref, decoder])

    message = Protobuf.Encoder.encode(request)

    stream_request =
      ArcticBase.StreamRequest.create(service_name, rpc, message, ref, stream_reader_pid)

    with :ok <- channel.adapter.module.request_stream(channel, stream_request) do
      {:ok, ArcticBase.Stream.new(ref, stream_reader_pid)}
    end
  end

  @spec unary_request(ArcticBase.Channel.t(), String.t(), ArcticBase.Rpc.t(), struct) ::
          {:ok, struct} | {:error, ArcticBase.RpcError.t()}
  def unary_request(channel, service_name, rpc, request) do
    :ok = ArcticBase.Channel.validate_input(channel)
    :ok = ArcticBase.StubAdapter.validate_input(channel.adapter)

    message = Protobuf.Encoder.encode(request)

    unary_request = ArcticBase.UnaryRequest.create(service_name, rpc, message)

    case channel.adapter.module.request(channel, unary_request) do
      {:ok, response} ->
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

  defp decode_stream_data_to_response(message, response) do
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
