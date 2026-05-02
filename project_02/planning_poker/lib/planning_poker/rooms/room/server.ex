defmodule PlanningPoker.Rooms.Room.Server do
  use GenServer

  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Users.User

  @spec start_link(room_name :: String.t()) :: GenServer.on_start()
  def start_link(name), do: GenServer.start_link(__MODULE__, name, name: via_registry(name))

  @spec show(pid()) :: Room.t()
  def show(room_pid), do: GenServer.call(room_pid, :show)

  @spec join(pid(), User.t()) :: :ok | {:error, atom()}
  def join(room_pid, user), do: GenServer.call(room_pid, {:join, user})

  @spec leave(pid(), User.t()) :: :ok | {:error, atom()}
  def leave(room_pid, user), do: GenServer.call(room_pid, {:leave, user})

  @spec member?(pid(), User.t()) :: boolean()
  def member?(room_pid, user), do: GenServer.call(room_pid, {:member?, user})

  @spec vote(pid(), User.t(), integer()) :: :ok | {:error, atom()}
  def vote(room_pid, user, vote), do: GenServer.call(room_pid, {:vote, user, vote})

  @spec change_topic(pid(), String.t()) :: :ok
  def change_topic(room_pid, topic), do: GenServer.cast(room_pid, {:change_topic, topic})

  @spec clear_votes(pid()) :: :ok
  def clear_votes(room_pid), do: GenServer.cast(room_pid, :clear_votes)

  @impl true
  def init(room_name), do: {:ok, Room.new(room_name)}

  @impl true
  def handle_call({:join, user}, _from, room) do
    case Room.join(room, user) do
      %Room{} = new_room -> {:reply, :ok, new_room}
      {:error, _} = error -> {:reply, error, room}
    end
  end

  @impl true
  def handle_call(:show, _from, room) do
    {:reply, room, room}
  end

  def handle_call({:leave, user}, _from, room) do
    case Room.leave(room, user) do
      %Room{} = new_room -> {:reply, :ok, new_room}
      {:error, _} = error -> {:reply, error, room}
    end
  end

  def handle_call({:vote, user, vote}, _from, room) do
    case Room.vote(room, user, vote) do
      %Room{} = new_room -> {:reply, :ok, new_room}
      {:error, _} = error -> {:reply, error, room}
    end
  end

  def handle_call({:member?, user}, _from, room) do
    {:reply, Room.member?(room, user), room}
  end

  @impl true
  def handle_cast(:clear_votes, room), do: {:noreply, Room.clear_votes(room)}

  def handle_cast({:change_topic, topic}, room), do: {:noreply, Room.change_topic(room, topic)}

  defp via_registry(room_name), do: {:via, Registry, {Room.Registry, room_name}}
end
