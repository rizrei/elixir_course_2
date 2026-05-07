defmodule PlanningPoker.Sockets.Socket.Router do
  def route("login " <> username) do
    {:ok, {PlanningPoker.Controllers.UsersController, :login, [username]}}
  end

  def route("logout") do
    {:ok, {PlanningPoker.Controllers.UsersController, :logout, []}}
  end

  def route("list_rooms") do
    {:ok, {PlanningPoker.Controllers.RoomsController, :index, []}}
  end

  def route("show_room " <> room_name) do
    {:ok, {PlanningPoker.Controllers.RoomsController, :show, [room_name]}}
  end

  def route("create_room " <> room_name) do
    {:ok, {PlanningPoker.Controllers.RoomsController, :create, [room_name]}}
  end

  def route("delete_room " <> room_name) do
    {:ok, {PlanningPoker.Controllers.RoomsController, :delete, [room_name]}}
  end

  def route("join " <> room_name) do
    {:ok, {PlanningPoker.Controllers.RoomsController, :join, [room_name]}}
  end

  def route("leave " <> room_name) do
    {:ok, {PlanningPoker.Controllers.RoomsController, :leave, [room_name]}}
  end

  def route("change_topic " <> payload) do
    case String.split(payload, ":") do
      [_room_name, _topic] = args ->
        {:ok, {PlanningPoker.Controllers.RoomsController, :change_topic, args}}

      _ ->
        {:error, :invalid_route}
    end
  end

  def route("vote " <> payload) do
    case String.split(payload, ":") do
      [_room_name, _vote] = args ->
        {:ok, {PlanningPoker.Controllers.RoomsController, :vote, args}}

      _ ->
        {:error, :invalid_route}
    end
  end

  def route(_), do: {:error, :invalid_route}
end
