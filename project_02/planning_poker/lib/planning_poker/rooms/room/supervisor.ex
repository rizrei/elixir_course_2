defmodule PlanningPoker.Rooms.Room.Supervisor do
  use DynamicSupervisor

  alias PlanningPoker.Rooms.Room

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_room(room_name) do
    DynamicSupervisor.start_child(__MODULE__, {Room.Server, room_name})
  end

  def find_room(room_name) do
    case Registry.lookup(Room.Registry, room_name) do
      [{room_pid, _}] -> {:ok, room_pid}
      [] -> {:error, :room_not_found}
    end
  end

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)
end
