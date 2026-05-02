defmodule PlanningPoker.Rooms do
  alias PlanningPoker.Users.User
  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Rooms.Room.Server, as: RoomServer
  alias PlanningPoker.Rooms.Room.Supervisor, as: RoomSupervisor

  @errors %{
    already_started: "Room already started",
    only_leader_can_start_room: "Only leader can start the room",
    only_leader_can_change_topic: "Only leader can change room topic",
    room_not_found: "Room not found",
    user_already_joined: "User already joined the room",
    user_not_found: "User not found"
  }

  @spec rooms_list() :: [String.t()]
  def rooms_list do
    Registry.select(Room.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
  end

  @spec show_room(String.t()) :: Room.t()
  def show_room(room_name) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name) do
      RoomServer.show(room_pid)
    else
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
    end
  end

  @spec create_room(String.t(), User.t()) :: :ok | {:error, String.t()}
  def create_room(room_name, user) do
    with :ok <- authorize_leader_user(user),
         {:ok, room_pid} <- RoomSupervisor.start_room(room_name),
         :ok <- RoomServer.join(room_pid, user) do
      :ok
    else
      {:error, :user_already_joined} -> {:error, @errors.user_already_joined}
      {:error, :unauthorized_user} -> {:error, @errors.only_leader_can_start_room}
      {:error, {:already_started, _pid}} -> {:error, @errors.already_started}
    end
  end

  @spec delete_room(String.t(), User.t()) :: :ok | {:error, String.t()}
  def delete_room(room_name, user) do
    with :ok <- authorize_leader_user(user),
         :ok <- RoomSupervisor.stop_room(room_name) do
      :ok
    else
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
      {:error, :unauthorized_user} -> {:error, @errors.only_leader_can_start_room}
    end
  end

  @spec join_room(String.t(), User.t()) :: :ok | {:error, String.t()}
  def join_room(room_name, user) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- RoomServer.join(room_pid, user) do
      :ok
    else
      {:error, :user_already_joined} -> {:error, @errors.user_already_joined}
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
    end
  end

  @spec leave_room(String.t(), User.t()) :: :ok | {:error, String.t()}
  def leave_room(room_name, user) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- RoomServer.leave(room_pid, user) do
      :ok
    else
      {:error, :user_not_found} -> {:error, @errors.user_not_found}
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
    end
  end

  @spec vote(String.t(), User.t(), String.t()) :: :ok | {:error, String.t()}
  def vote(room_name, user, vote) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- RoomServer.vote(room_pid, user, vote) do
      :ok
    else
      {:error, :user_not_found} -> {:error, @errors.user_not_found}
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
    end
  end

  @spec change_topic(String.t(), User.t(), String.t()) :: :ok | {:error, String.t()}
  def change_topic(room_name, user, topic) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name),
         :ok <- authorize_room_user(room_pid, user),
         :ok <- authorize_leader_user(user),
         :ok <- RoomServer.change_topic(room_pid, topic),
         :ok <- RoomServer.clear_votes(room_pid) do
      :ok
    else
      {:error, :unauthorized_user} -> {:error, @errors.only_leader_can_change_topic}
      {:error, :user_not_found} -> {:error, @errors.user_not_found}
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
    end
  end

  defp authorize_leader_user(user) do
    if User.leader?(user), do: :ok, else: {:error, :unauthorized_user}
  end

  defp authorize_room_user(room_pid, user) do
    if RoomServer.member?(room_pid, user), do: :ok, else: {:error, :user_not_found}
  end
end
