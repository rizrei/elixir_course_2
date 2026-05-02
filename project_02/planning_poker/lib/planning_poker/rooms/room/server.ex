defmodule PlanningPoker.Rooms.Room.Server do
  use GenServer

  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Users.User

  @spec start_link(room_name :: String.t()) :: GenServer.on_start()
  def start_link(name), do: GenServer.start_link(__MODULE__, name, name: via_registry(name))

  @spec join(pid(), User.t()) :: :ok | {:error, atom()}
  def join(room_pid, user), do: GenServer.call(room_pid, {:join, user})

  @spec leave(pid(), User.t()) :: :ok | {:error, atom()}
  def leave(room_pid, user), do: GenServer.call(room_pid, {:leave, user})

  # def broadcast(room_pid, event), do: GenServer.call(room_pid, {:broadcast, event})

  @impl true
  def init(room_name), do: {:ok, Room.new(room_name)}

  @impl true
  def handle_call({:join, user}, _from, room) do
    case Room.join(room, user) do
      %Room{} = new_room -> {:reply, :ok, new_room}
      {:error, _} = error -> {:reply, error, room}
    end
  end

  def handle_call({:leave, user}, _from, room) do
    case Room.leave(room, user) do
      %Room{} = new_room -> {:reply, :ok, new_room}
      {:error, _} = error -> {:reply, error, room}
    end
  end

  defp via_registry(room_name), do: {:via, Registry, {Room.Registry, room_name}}

  # def handle_call({:broadcast, event}, _from, state) do
  #   state = do_broadcast(event, state)
  #   {:reply, :ok, state}
  # end

  # # catch all
  # def handle_call(msg, _from, state) do
  #   Logger.error("Room unknown call #{inspect(msg)}")
  #   {:reply, :error, state}
  # end

  # defp do_broadcast(event, state) do
  #   Logger.info("Room.do_broadcast #{inspect(event)}")

  #   Enum.each(
  #     state.participants,
  #     fn user ->
  #       case Registry.lookup(:sessions_registry, user.id) do
  #         [] -> Logger.error("Session for user #{user.id} is not found")
  #         [{session_pid, _}] -> PlanningPoker.Sessions.Session.send_event(session_pid, event)
  #       end
  #     end
  #   )

  #   state
  # end
end
