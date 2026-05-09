defmodule PlanningPoker.Sockets.SocketTest do
  use ExUnit.Case

  alias PlanningPoker.Sockets.Socket
  alias PlanningPoker.Users.User
  alias PlanningPoker.Rooms

  setup do
    user = %User{id: 1, name: "TestUser", role: :leader}
    socket = %Socket{socket_pid: self(), user: nil}
    Rooms.create("Room1", user)

    {:ok, user: user, socket: socket}
  end

  describe "login/2" do
    test "sets user on socket", %{socket: socket, user: user} do
      logged_in = Socket.login(socket, user)

      assert logged_in.user == user
      assert logged_in.socket_pid == socket.socket_pid
    end
  end

  describe "logout/1" do
    test "clears user from socket", %{socket: socket, user: user} do
      socket = Socket.login(socket, user)
      logged_out = Socket.logout(socket)

      assert logged_out.user == nil
    end

    test "does nothing if user not logged in", %{socket: socket} do
      logged_out = Socket.logout(socket)

      assert logged_out.user == nil
    end
  end

  describe "authenticate_user/1" do
    test "returns ok if user is authenticated", %{socket: socket, user: user} do
      authenticated_socket = Socket.login(socket, user)

      assert Socket.authenticate_user(authenticated_socket) == :ok
    end

    test "returns error if user not authenticated", %{socket: socket} do
      assert {:error, :unauthenticated_user} == Socket.authenticate_user(socket)
    end
  end

  describe "handle_request/2" do
    test "routes requests to controllers", %{socket: socket} do
      assert {%Socket{}, "Rooms:\nRoom1\n"} = Socket.handle_request(socket, "list")
    end

    test "returns error message for invalid request", %{socket: socket} do
      assert {_socket, "Unknown request"} = Socket.handle_request(socket, "invalid_command")
    end
  end
end
