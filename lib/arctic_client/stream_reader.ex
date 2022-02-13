defmodule ArcticClient.Stub.StreamReader do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl GenServer
  def init([caller_pid, ref, decoder]) do
    {:ok, %{caller_pid: caller_pid, ref: ref, data_buffer: [], decoder: decoder}}
  end

  @impl GenServer
  def handle_info({:data, response, data}, state) do
    data_buffer = [data | state.data_buffer]
    buffer = data_buffer |> Enum.reverse() |> IO.iodata_to_binary()

    case ArcticBase.Message.get_message(buffer) do
      {{_, message}, rest} ->
        send(state.caller_pid, {:response, state.ref, state.decoder.(message)})
        {:noreply, %{state | data_buffer: [rest]}}

      false ->
        {:noreply, %{state | data_buffer: data_buffer}}
    end
  end

  def handle_info({:done, response}, state) do
    grpc_headers = get_rpc_status(response.headers)

    unless grpc_headers["grpc-status"] == "0" do
      send(state.caller_pid, {:response, {:error, state.ref, to_grpc_error(grpc_headers)}})
    end

    send(state.caller_pid, {:done, state.ref})
    {:stop, :normal, state}
  end

  defp get_rpc_status(headers) do
    headers
    |> Enum.filter(fn {key, _} -> key in ["grpc-message", "grpc-status"] end)
    |> Map.new()
  end

  defp to_grpc_error(headers) do
    ArcticBase.RpcError.exception(
      message: headers["grpc-message"],
      status: String.to_integer(headers["grpc-status"] || "99")
    )
  end
end
