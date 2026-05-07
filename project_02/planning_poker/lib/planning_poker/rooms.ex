defmodule PlanningPoker.Rooms do
  alias PlanningPoker.Users.User
  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Rooms.Room.Server, as: RoomServer
  alias PlanningPoker.Rooms.Room.Supervisor, as: RoomSupervisor

  @spec list() :: [String.t()]
  def list do
    Registry.select(Room.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
  end

  @spec show(String.t(), User.t()) :: Room.t() | {:error, atom()}
  def show(room_name, user) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- authorize_room_user(room_pid, user) do
      RoomServer.show(room_pid)
    end
  end

  @spec create(String.t(), User.t()) :: :ok | {:error, atom()}
  def create(room_name, user) do
    with :ok <- authorize_leader_user(user),
         {:ok, room_pid} <- RoomSupervisor.start_room(room_name) do
      RoomServer.join(room_pid, user)
    end
  end

  @spec delete(String.t(), User.t()) :: :ok | {:error, atom()}
  def delete(room_name, user) do
    with :ok <- authorize_leader_user(user) do
      RoomSupervisor.stop_room(room_name)
    end
  end

  @spec join(String.t(), User.t()) :: :ok | {:error, atom()}
  def join(room_name, user) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name) do
      RoomServer.join(room_pid, user)
    end
  end

  @spec leave(String.t(), User.t()) :: :ok | {:error, atom()}
  def leave(room_name, user) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- authorize_room_user(room_pid, user) do
      RoomServer.leave(room_pid, user)
    end
  end

  @spec vote(String.t(), User.t(), String.t()) :: :ok | {:error, atom()}
  def vote(room_name, user, vote) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- authorize_room_user(room_pid, user) do
      RoomServer.vote(room_pid, user, vote)
    end
  end

  @spec change_topic(String.t(), User.t(), String.t()) :: :ok | {:error, atom()}
  def change_topic(room_name, user, topic) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- authorize_room_user(room_pid, user),
         :ok <- authorize_leader_user(user),
         :ok <- RoomServer.change_topic(room_pid, topic),
         :ok <- RoomServer.clear_votes(room_pid) do
      :ok
    end
  end

  defp authorize_leader_user(user) do
    if User.leader?(user), do: :ok, else: {:error, :unauthorized_user}
  end

  defp authorize_room_user(room_pid, user) do
    if RoomServer.member?(room_pid, user), do: :ok, else: {:error, :unauthorized_user}
  end
end
