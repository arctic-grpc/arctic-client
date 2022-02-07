# defmodule DemoAdapter do
#  @behaviour ArcticDef.StubAdapter
#  alias ArcticClient.UnaryResponseContext
#
#  @impl true
#  def connect(channel) do
#    case MintGRPC.connect(:http, channel.host, channel.port) do
#      {:ok, conn_pid} ->
#        {:ok, put_in(channel, [Access.key(:adapter), Access.key(:conn_pid)], conn_pid)}
#
#      {:error, reason} ->
#        {:error, "Error when opening connection: #{inspect(reason)}"}
#    end
#  end
#
#  @impl true
#  def send_request(
#        channel,
#        service_name,
#        # %{channel: %{adapter_payload: %{conn_pid: conn_pid}}, path: path} = stream,
#        rpc,
#        unary_request
#      ) do
#    # headers = GRPC.Transport.HTTP2.client_headers_without_reserved(stream, opts)
#    headers =
#      Keyword.new(unary_request.headers) ++
#        [
#          {"grpc-timeout", "10S"},
#          {"content-type", "application/grpc"},
#          {"user-agent", "arctic-mint-elixir/0.5.0-beta.1"},
#          {"te", "trailers"}
#        ]
#
#    {:ok, data, _} = ArcticUtils.Message.to_data(unary_request.message, [])
#
#    # TODO: what are the possible return values?
#    {:ok,
#     MintGRPC.rpc(
#       channel.adapter.conn_pid,
#       :unary,
#       unary_request.path,
#       headers,
#       data
#     )}
#
#    # GRPC.Client.Stream.put_payload(stream, :stream_ref, stream_pid)
#  end
#
#  def recv_headers(context, channel, stream_pid) do
#    case MintGPRC.ResponseStreamer.await(stream_pid) do
#      {:headers, %{done: done?, status: status} = response} ->
#        headers = Enum.into(response.headers, %{})
#
#        context
#        |> UnaryResponseContext.put_headers(headers)
#        |> UnaryResponseContext.put_done(done?)
#        |> UnaryResponseContext.put_status(status)
#
#      other ->
#        UnaryResponseContext.put_error(
#          context,
#          %ArcticDef.RPCError{
#            message: "unexpected when waiting for headers: #{inspect(other)}",
#            status: 0
#          }
#        )
#    end
#  end
#
#  def recv_data_or_trailers(context, channel, stream_ref) do
#    case MintGPRC.ResponseStreamer.await(stream_ref) do
#      {:data, %{data: data}} ->
#        # {:data, :binary.list_to_bin(data)}
#        UnaryResponseContext.put_data(context, :binary.list_to_bin(data))
#
#      {:trailer_headers, %{trailer_headers: trailer_headers}} ->
#        # Process.exit(stream_ref, :kill)
#        # {:trailers, trailer_headers}
#
#        headers = Enum.into(trailer_headers, %{})
#        UnaryResponseContext.put_headers(context, headers)
#
#      {:done, response} ->
#        headers = Enum.into(response.headers, %{})
#
#        context
#        |> UnaryResponseContext.put_headers(headers)
#        |> UnaryResponseContext.put_done(true)
#
#      other ->
#        UnaryResponseContext.put_error(
#          context,
#          %ArcticDef.RPCError{
#            message: "unexpected when waiting for data: #{inspect(other)}",
#            status: 1
#          }
#        )
#    end
#  end
# end
#
# defmodule MintGRPC do
#  @moduledoc """
#  Documentation for `MintGRPC`.
#  """
#
#  @doc """
#  Hello world.
#
#  ## Examples
#
#      iex> {:ok, pid} = MintGRPC.connect(:http, "localhost", 5001)
#      iex> headers = [{"grpc-timeout", "10S"}, {"content-type", "application/grpc"}, {"user-agent", "mint-grpc-elixir/0.1.0"}, {"te", "trailers"}]
#      iex> body = <<0, 0, 0, 0, 2, 8, 1>>
#      iex> {:ok, conn, ref} = MintGRPC.rpc(conn, :unary, "/micro.User/Get", headers, body)
#      iex> MintGPRC.await(conn, ref)
#      {:ok, MintGPRC.Response{cycle: done, with_or_without_trailer, with_or_without_data, with_headers}}
#      {:ok, MintGPRC.Response{cycle: in_progress, with_no_body_or_partial_body, with_partial_headers}}
#      {:error, :timeout | :connection_error | :stream_error| ...}
#        1. is it finished or net?({:done, ref}
#          if it's 
#        2. 
#      <<0, 0, 0, 0, 14, 18, 3, 66, 111, 98, 26, 5, 83, 109, 105, 116, 104, 32, 41>>
#      iex> MintGRPC.rpc(conn, :server_stream, "/micro.User/Get", headers, body)
#      <<0, 0, 0, 0, 14, 18, 3, 66, 111, 98, 26, 5, 83, 109, 105, 116, 104, 32, 41>>
#
#
#    MintGRPC.rpc:
#            * Spwan a gen server(add it to a supervisor)
#            * create a request:
#              * Store the reference %{"refxxx" : %Response{}}
#              * Listen for incomming data
#            * returns {:ok, conn?, ref}
#   MintGRPC.await:
#            handle_call({:await, conn?, ref, timeout}, from)
#            stores the ref as awaiting reply
#            retuens {:noreply, %{state| pending_response: %{ref => from}}}
#   MintGRPC.handl_info({tcp, port}):
#            runs Mint.HTTP2.stream
#            parse stuff and update the state
#            send GenServer.reply(state.pending_response[ref])
#
#
#  """
#  def hello do
#    :world
#  end
#
#  @doc """
#    iex> {:ok, pid} = MintGRPC.connect(:http, "localhost", 50051)
#  """
#  def connect(schema, address, port, extra_opts \\ []) do
#    opts = [schema: schema, address: address, port: port, opts: extra_opts]
#
#    with {:ok, pid} <- MintGRPC.Connection.start_link(opts),
#         :ok <- MintGRPC.Connection.check_connect_status(pid) do
#      {:ok, pid}
#    end
#  end
#
#  @doc """
#      iex> headers = [{"grpc-timeout", "10S"}, {"content-type", "application/grpc"}, {"user-agent", "mint-grpc-elixir/0.1.0"}, {"te", "trailers"}]
#      iex> body = <<0, 0, 0, 0, 2, 8, 1>>
#      iex> MintGRPC.rpc(pid, :unary, "/micro.User/Get", headers, body)
#  """
#  def rpc(pid, :unary, path, headers, body) do
#    IO.inspect(path)
#    MintGRPC.Connection.request(pid, {:unary, path, headers, body})
#  end
# end
#
# defmodule MintGRPC.HTTP2Client do
#  defstruct [:schema, :address, :port]
#
#  def connect(%__MODULE__{} = client) do
#    Mint.HTTP2.connect(client.schema, client.address, client.port)
#  end
# end
#
# defmodule MintGRPC.Connection do
#  use GenServer
#  alias MintGRPC.HTTP2Client
#
#  defstruct [:conn, :client, :extra_opts, :connect_error, :in_flight_requests]
#
#  def start_link(opts) do
#    GenServer.start_link(__MODULE__, opts, [])
#  end
#
#  def check_connect_status(pid) do
#    GenServer.call(pid, :check_connect_result)
#  end
#
#  def request(pid, {:unary, path, headers, body}) do
#    GenServer.call(pid, {:request, :unary, path, headers, body})
#  end
#
#  @impl true
#  def init(opts) do
#    state = %__MODULE__{
#      conn: nil,
#      client: %HTTP2Client{
#        schema: opts[:schema],
#        address: opts[:address],
#        port: opts[:port]
#      },
#      extra_opts: opts[:extra_opts],
#      in_flight_requests: %{}
#    }
#
#    # IO.inspect("ready #{__MODULE__} ...")
#
#    {:ok, state, {:continue, :connect}}
#  end
#
#  @impl true
#  def handle_continue(:connect, state) do
#    case HTTP2Client.connect(state.client) do
#      {:ok, conn} ->
#        {:noreply, %{state | conn: conn}}
#
#      {:error, reason} ->
#        {:noreply, %{state | connect_error: {:error, reason}}}
#    end
#  end
#
#  @impl true
#  def handle_call({:request, :unary, path, headers, body}, _, state) do
#    # Mint.HTTP2.request(conn, "POST", "/micro.User/Get", headers, body)
#    # IO.inspect(["POST", path, headers, body])
#    {:ok, conn, ref} = Mint.HTTP2.request(state.conn, "POST", path, headers, body)
#
#    {:ok, response_stream} = MintGPRC.ResponseStreamer.start(self())
#    # TODO monitor the pid and remove it when receive :DOWN
#
#    in_flight_requests = Map.put(state.in_flight_requests, ref, response_stream)
#
#    {:reply, response_stream,
#     %{
#       state
#       | conn: conn,
#         in_flight_requests: in_flight_requests
#     }}
#  end
#
#  @impl true
#  def handle_call(:check_connect_result, _, state) do
#    connect_result =
#      case state do
#        %{conn: nil, connect_error: connect_error} -> connect_error
#        _ -> :ok
#      end
#
#    {:reply, connect_result, state}
#  end
#
#  @impl true
#  def handle_call(:ping, _, state) do
#    {:reply, :pong, state}
#  end
#
#  @impl true
#  def handle_info({:tcp, _, _} = message, state) do
#    conn =
#      case Mint.HTTP2.stream(state.conn, message) do
#        {:ok, conn, response} ->
#          response
#          |> IO.inspect()
#          |> Enum.map(fn
#            {part, ref, message} ->
#              send(state.in_flight_requests[ref], {:http2, part, message})
#
#            {:done, ref} ->
#              send(state.in_flight_requests[ref], {:http2, :done})
#          end)
#          |> IO.inspect()
#
#          conn
#
#        _ ->
#          state.conn
#      end
#
#    {:noreply, %{state | conn: conn}}
#  end
#
#  @impl true
#  def handle_info({:tcp_closed, _} = message, state) do
#    {:noreply, %{state | in_flight_requests: %{}, conn: nil}}
#  end
# end
#
# defmodule MintGPRC.ResponseStreamer do
#  use GenServer
#  defstruct [:status, :headers, :trailer_headers, :data, :done, :waiting_client, :messages]
#
#  def to_stream(pid) do
#    Stream.resource(
#      fn ->
#        pid
#      end,
#      fn pid ->
#        case Process.alive?(pid) && await(pid) do
#          false ->
#            {:halt, pid}
#
#          {:done, state} ->
#            Process.exit(pid, :kill)
#            {[{:done, state}], pid}
#
#          {step, state} ->
#            {[{step, state}], pid}
#        end
#      end,
#      fn pid ->
#        Process.exit(pid, :kill)
#      end
#    )
#  end
#
#  def start(connection_pid) do
#    GenServer.start(__MODULE__, connection_pid, [])
#  end
#
#  def exito(pid) do
#    GenServer.call(pid, :exit)
#  end
#
#  def get_state(pid) do
#    GenServer.call(pid, :get_state_and_flush_data)
#  end
#
#  def await(pid) do
#    # TODO: implement timeout
#    GenServer.call(pid, :await)
#  end
#
#  @impl true
#  def init(connection_pid) do
#    # TODO: stop the server if receive {:DOWN, ...}
#    Process.monitor(connection_pid)
#    {:ok, %__MODULE__{headers: [], done: false, data: [], messages: []}}
#  end
#
#  @impl true
#  def handle_call(:exit, _, state) do
#    Process.exit(self(), :normal)
#    {:reply, :ok, state}
#  end
#
#  @impl true
#  def handle_call(:await, from, state) do
#    case state.messages do
#      [] ->
#        {:noreply, %{state | waiting_client: from}}
#
#      [msg | messages] ->
#        {:reply, msg, %{state | messages: messages, waiting_client: nil}}
#    end
#  end
#
#  @impl true
#  def handle_call(:get_state_and_flush_data, _, state) do
#    return = state
#    {:reply, return, %{state | data: []}}
#  end
#
#  @impl true
#  def handle_info({:http2, :status, status}, state) do
#    {:noreply, %{state | status: status}}
#  end
#
#  @impl true
#  def handle_info({:http2, :headers, headers}, %{headers: []} = state) do
#    state = %{state | headers: headers}
#
#    state =
#      if state.waiting_client do
#        GenServer.reply(state.waiting_client, {:headers, state})
#        %{state | waiting_client: nil}
#      else
#        %{state | messages: state.messages ++ [{:headers, state}]}
#      end
#
#    {:noreply, state}
#  end
#
#  @impl true
#  def handle_info({:http2, :headers, headers}, state) do
#    state = %{state | trailer_headers: headers, headers: state.headers ++ headers}
#
#    state =
#      if state.waiting_client do
#        GenServer.reply(state.waiting_client, {:trailer_headers, state})
#        %{state | waiting_client: nil}
#      else
#        %{state | messages: state.messages ++ [{:trailer_headers, state}]}
#      end
#
#    {:noreply, state}
#  end
#
#  @impl true
#  def handle_info({:http2, :data, data}, state) do
#    state = %{state | data: state.data ++ [data]}
#
#    state =
#      if state.waiting_client do
#        GenServer.reply(state.waiting_client, {:data, state})
#        %{state | data: [], waiting_client: nil}
#      else
#        %{state | messages: state.messages ++ [{:data, state}], data: []}
#      end
#
#    {:noreply, state}
#  end
#
#  @impl true
#  def handle_info({:http2, :done}, state) do
#    state = %{state | done: true}
#
#    state =
#      if state.waiting_client do
#        GenServer.reply(state.waiting_client, {:done, state})
#        %{state | data: [], waiting_client: nil}
#      else
#        %{state | messages: state.messages ++ [{:done, state}]}
#      end
#
#    {:noreply, state}
#  end
# end
