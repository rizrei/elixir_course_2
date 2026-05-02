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

  @spec start_room(String.t(), User.t()) :: :ok | {:error, String.t()}
  def start_room(room_name, user) do
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

  @spec show(String.t()) :: Room.t()
  def show(room_name) do
    with {:ok, room_pid} <- RoomSupervisor.find_room(room_name) do
      RoomServer.show(room_pid)
    else
      {:error, :room_not_found} -> {:error, @errors.room_not_found}
    end
  end

  defp authorize_leader_user(user) do
    (User.leader?(user) && :ok) || {:error, :unauthorized_user}
  end

  defp authorize_room_user(room_pid, user) do
    (RoomServer.member?(room_pid, user) && :ok) || {:error, :user_not_found}
  end
end

# defmodule PlanningPoker.Rooms do
#   require Logger

#   defmodule Room do
#     use GenServer

#     alias PlanningPoker.Model.Room

#     def start_link({room_name, process_name}) do
#       GenServer.start_link(__MODULE__, room_name, name: process_name)
#     end

#     def join(room_pid, user) do
#       GenServer.call(room_pid, {:join, user})
#     end

#     def leave(room_pid, user) do
#       GenServer.call(room_pid, {:leave, user})
#     end

#     def broadcast(room_pid, event) do
#       GenServer.call(room_pid, {:broadcast, event})
#     end

#     @impl true
#     def init(room_name) do
#       state = %Room{
#         name: room_name,
#         participants: []
#       }

#       Logger.info("#{inspect(state)} has started")
#       {:ok, state}
#     end

#     @impl true
#     def handle_call({:join, user}, _from, state) do
#       if user in state.participants do
#         {:reply, {:error, :already_joined}, state}
#       else
#         participants = [user | state.participants]
#         state = %Room{state | participants: participants}
#         Logger.info("user has joined the room #{inspect(state)}")
#         state = do_broadcast({:joined, user, state.name}, state)
#         {:reply, :ok, state}
#       end
#     end

#     def handle_call({:leave, user}, _from, state) do
#       participants = List.delete(state.participants, user)
#       state = %Room{state | participants: participants}
#       Logger.info("user has left the room #{inspect(state)}")
#       state = do_broadcast({:leaved, user, state.name}, state)
#       {:reply, :ok, state}
#     end

#     def handle_call({:broadcast, event}, _from, state) do
#       state = do_broadcast(event, state)
#       {:reply, :ok, state}
#     end

#     # catch all
#     def handle_call(msg, _from, state) do
#       Logger.error("Room unknown call #{inspect(msg)}")
#       {:reply, :error, state}
#     end

#     defp do_broadcast(event, state) do
#       Logger.info("Room.do_broadcast #{inspect(event)}")

#       Enum.each(
#         state.participants,
#         fn user ->
#           case Registry.lookup(:sessions_registry, user.id) do
#             [] -> Logger.error("Session for user #{user.id} is not found")
#             [{session_pid, _}] -> PlanningPoker.Sessions.Session.send_event(session_pid, event)
#           end
#         end
#       )

#       state
#     end
#   end

#   defmodule Sup do
#     use DynamicSupervisor

#     @sup_name :room_sup
#     # TODO leaked into RoomManager
#     @registry_name :room_registry

#     def start_link(_) do
#       Registry.start_link(keys: :unique, name: @registry_name)
#       DynamicSupervisor.start_link(__MODULE__, :no_args, name: @sup_name)
#     end

#     def start_room(room_name) do
#       process_name = {:via, Registry, {@registry_name, room_name}}
#       spec = {Room, {room_name, process_name}}
#       DynamicSupervisor.start_child(@sup_name, spec)
#     end

#     @impl true
#     def init(_) do
#       Logger.info("#{@sup_name} has started")
#       DynamicSupervisor.init(strategy: :one_for_one)
#     end
#   end

#   defmodule RoomManager do
#     use GenServer

#     defmodule State do
#       defstruct [:rooms]
#     end

#     @process_name :room_manager

#     def start_link(_) do
#       GenServer.start_link(__MODULE__, :no_args, name: @process_name)
#     end

#     def start_room(room_name) do
#       GenServer.call(@process_name, {:start_room, room_name})
#     end

#     def find_room(room_name) do
#       case Registry.lookup(:room_registry, room_name) do
#         [{room_pid, _}] -> {:ok, room_pid}
#         [] -> {:error, :not_found}
#       end
#     end

#     @impl true
#     def init(_) do
#       state = %State{
#         rooms: []
#       }

#       Logger.info("RoomManager has started, #{inspect(state)}")
#       {:ok, state}
#     end

#     @impl true
#     def handle_call({:start_room, room_name}, _from, %State{rooms: rooms} = state) do
#       {:ok, _} = Sup.start_room(room_name)
#       state = %State{state | rooms: [room_name | rooms]}
#       Logger.info("RoomManager has started room #{inspect(state)}")
#       {:reply, :ok, state}
#     end

#     # TODO catch all
#   end
# end
