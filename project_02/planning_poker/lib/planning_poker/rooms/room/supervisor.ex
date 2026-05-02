defmodule PlanningPoker.Rooms.Room.Supervisor do
  use DynamicSupervisor

  alias PlanningPoker.Rooms.Room

  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_room(String.t()) :: DynamicSupervisor.on_start_child()
  def start_room(room_name) do
    DynamicSupervisor.start_child(__MODULE__, {Room.Server, room_name})
  end

  @spec stop_room(pid()) :: :ok | {:error, :room_not_found}
  def stop_room(room_pid) when is_pid(room_pid) do
    case DynamicSupervisor.terminate_child(__MODULE__, room_pid) do
      :ok -> :ok
      {:error, :not_found} -> {:error, :room_not_found}
    end
  end

  def stop_room(room_name) do
    case find_room(room_name) do
      {:ok, room_pid} -> stop_room(room_pid)
      {:error, _} = error -> error
    end
  end

  @spec find_room(String.t()) :: {:ok, pid()} | {:error, :room_not_found}
  def find_room(room_name) do
    case Registry.lookup(Room.Registry, room_name) do
      [{room_pid, _}] -> {:ok, room_pid}
      [] -> {:error, :room_not_found}
    end
  end

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)
end
