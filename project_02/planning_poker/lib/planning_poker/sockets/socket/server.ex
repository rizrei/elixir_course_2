defmodule PlanningPoker.Sockets.Socket.Server do
  use GenServer

  require Logger
  alias PlanningPoker.Sockets.Socket

  def start_link(args), do: GenServer.start_link(__MODULE__, Keyword.fetch!(args, :port))

  # def send_event(session_pid, event) do
  #   Logger.info("Session.send_event #{inspect(session_pid)} #{inspect(event)}")
  #   GenServer.cast(session_pid, {:send_event, event})
  # end

  @impl true
  def init(port) do
    # Logger.info("Session #{inspect(self())} has started, #{inspect(state)}")
    {:ok, %Socket{port: port}, {:continue, :listen_socket}}
  end

  @impl true
  def handle_continue(:listen_socket, %{port: port} = socket) do
    case :gen_tcp.accept(port) do
      {:ok, socket_pid} ->
        send(self(), :loop)
        {:noreply, %{socket | socket_pid: socket_pid}}

      {:error, _} = error ->
        {:stop, error, socket}
    end
  end

  # @impl true
  # def handle_cast({:send_event, event}, state) do
  #   data = Protocol.serialize(event)
  #   Logger.info("send_event #{data} to #{inspect(state.socket)}")
  #   :gen_tcp.send(state.socket, data <> "\n")
  #   {:noreply, state}
  # end

  @impl true
  def handle_info(:loop, %{socket_pid: socket_pid} = socket) do
    # IO.puts("Session #{inspect self()} #{state.session_id} is waiting for data #{inspect state}")
    case :gen_tcp.recv(socket_pid, 0, 1000) do
      {:ok, data} ->
        # IO.puts("Session #{state.session_id} has got data #{inspect(data)}")

        {socket, response} = Socket.handle_request(socket, String.trim(data))
        :gen_tcp.send(socket_pid, response <> "\n")
        send(self(), :loop)
        {:noreply, socket}

      {:error, :timeout} ->
        send(self(), :loop)
        {:noreply, socket}

      {:error, error} ->
        # IO.puts("Session #{state.session_id} has got #{inspect(error)}")
        Logger.info("Error", error: error)
        :gen_tcp.close(socket_pid)
        socket = Socket.logout(socket)
        {:noreply, socket, {:continue, :listen_socket}}
    end
  end

  # catch all
  # def handle_info(msg, state) do
  #   Logger.error("Session #{inspect(self())} unknown info #{inspect(msg)}")
  #   {:noreply, state}
  # end

  # defp handle_request(request, state) do
  #   case Protocol.deserialize(request) do
  #     {:error, error} ->
  #       {Protocol.serialize({:error, error}), state}

  #     event ->
  #       {result, state} = handle_event(event, state)
  #       {Protocol.serialize(result), state}
  #   end
  # end

  # defp handle_event({:login, name}, state) do
  #   alias PlanningPoker.UsersDatabase

  #   case UsersDatabase.get_by_name(name) do
  #     {:ok, user} ->
  #       Logger.info("auth as #{inspect(user)}")
  #       Registry.register(:sessions_registry, user.id, user)
  #       state = %State{state | %{state.data | user: user}}
  #       {:ok, state}

  #     {:error, :not_found} ->
  #       {{:error, :invalid_auth}, state}
  #   end
  # end

  # defp handle_event({:join_room, _room_name}, %State{user: nil} = state) do
  #   {{:error, :forbidden}, state}
  # end

  # defp handle_event({:join_room, room_name}, state) do
  #   response =
  #     case RoomManager.find_room(room_name) do
  #       {:ok, room_pid} -> Room.join(room_pid, state.user)
  #       error -> error
  #     end

  #   {response, state}
  # end

  # # catch all
  # defp handle_event(event, state) do
  #   Logger.error("Unknown event #{inspect(event)}")
  #   # status 500
  #   result = {:error, :unknown_error}
  #   {result, state}
  # end

  # defp on_client_disconnect(state) do
  #   Registry.unregister(:sessions_registry, state.user.id)
  #   {:ok, room_pid} = RoomManager.find_room("Room 1")
  #   Room.leave(room_pid, state.user)
  #   # RoomManager.leave_all_rooms(state.user)
  #   %State{state | user: nil}
  # end
end
