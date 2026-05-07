defmodule PlanningPoker.Controllers.RoomsController do
  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Sockets.Socket
  alias PlanningPoker.Serializers.{ErrorsSerializer, RoomsSerializer}

  def index(socket) do
    {:ok, {socket, RoomsSerializer.serialize(:index, Rooms.list_rooms())}}
  end

  def show(%{user: user} = socket, room_name) do
    with :ok <- Socket.authenticate_user(socket),
         %Room{} = room <- Rooms.show_room(room_name, user) do
      {:ok, {socket, RoomsSerializer.serialize(:show, room)}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end

  @spec create(Socket.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def create(%{user: user} = socket, room_name) do
    with :ok <- Socket.authenticate_user(socket),
         :ok <- Rooms.create_room(room_name, user) do
      {:ok, {socket, RoomsSerializer.serialize(:create, room_name)}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end

  @spec delete(Socket.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def delete(%{user: user} = socket, room_name) do
    with :ok <- Socket.authenticate_user(socket),
         :ok <- Rooms.delete_room(room_name, user) do
      {:ok, {socket, RoomsSerializer.serialize(:delete, room_name)}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end

  @spec join(Socket.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def join(%{user: user} = socket, room_name) do
    with :ok <- Socket.authenticate_user(socket),
         :ok <- Rooms.join_room(room_name, user) do
      {:ok, {socket, RoomsSerializer.serialize(:join, {room_name, user})}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end

  @spec leave(Socket.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def leave(%{user: user} = socket, room_name) do
    with :ok <- Socket.authenticate_user(socket),
         :ok <- Rooms.leave_room(room_name, user) do
      {:ok, {socket, RoomsSerializer.serialize(:leave, {room_name, user})}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end

  @spec change_topic(Socket.t(), String.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def change_topic(%{user: user} = socket, room_name, topic) do
    with :ok <- Socket.authenticate_user(socket),
         :ok <- Rooms.change_topic(room_name, user, topic) do
      {:ok, {socket, RoomsSerializer.serialize(:change_topic, {room_name, topic})}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end

  @spec vote(Socket.t(), String.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def vote(%{user: user} = socket, room_name, vote) do
    with :ok <- Socket.authenticate_user(socket),
         :ok <- Rooms.vote(room_name, user, vote) do
      {:ok, {socket, RoomsSerializer.serialize(:vote, user)}}
    else
      {:error, _} = error -> {:ok, {socket, ErrorsSerializer.serialize(error)}}
    end
  end
end
