defmodule PlanningPoker.SocketIntegrationTest do
  use ExUnit.Case

  alias PlanningPoker.TCPClient
  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.Room.Supervisor, as: RoomSupervisor

  setup_all do
    [
      port: Application.fetch_env!(:planning_poker, :port),
      leader: "Helen",
      user1: "Yura",
      user2: "Bob"
    ]
  end

  setup do
    on_exit(fn -> Enum.map(Rooms.list(), &RoomSupervisor.stop_room/1) end)
    :ok
  end

  describe "authentication" do
    test "login with valid username", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      {:ok, response} = TCPClient.send_and_recv(socket, "login #{cont.user1}")
      assert response == "Logged in, name: #{cont.user1} role: participant"
      TCPClient.close(socket)
    end

    test "commands without login return error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      {:ok, response} = TCPClient.send_and_recv(socket, "create #{room}")
      assert response == "User must be authenticated to perform this action"
      TCPClient.close(socket)
    end

    test "logout and subsequent commands fail", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      TCPClient.send_and_recv(socket, "login #{cont.user1}")
      {:ok, response} = TCPClient.send_and_recv(socket, "logout")
      assert response == "Logged out, name: #{cont.user1}"
      room = "Room1"
      {:ok, response} = TCPClient.send_and_recv(socket, "create #{room}")
      assert response == "User must be authenticated to perform this action"
      TCPClient.close(socket)
    end
  end

  describe "room operations" do
    test "create room", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      {:ok, response} = TCPClient.send_and_recv(socket, "create #{room}")
      assert response == "Room #{room} created"
      TCPClient.close(socket)
    end

    test "list rooms", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room1 = "Room1"
      room2 = "Room2"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room1}")
      TCPClient.send_and_recv(socket, "create #{room2}")
      {:ok, response} = TCPClient.send_and_recv(socket, "list")
      assert String.contains?(response, ["Rooms:", room1, room2])
      TCPClient.close(socket)
    end

    test "show room details", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "show #{room}")
      assert String.contains?(response, room)
      TCPClient.close(socket)
    end

    test "join room", cont do
      {:ok, socket1} = TCPClient.connect(cont.port)
      {:ok, socket2} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket1, "login #{cont.leader}")
      TCPClient.send_and_recv(socket1, "create #{room}")
      TCPClient.send_and_recv(socket2, "login #{cont.user1}")
      {:ok, response} = TCPClient.send_and_recv(socket2, "join #{room}")
      assert response == "#{cont.user1} participant has joined to the room #{room}"
      Enum.each([socket1, socket2], &TCPClient.close/1)
    end

    test "leave room", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      TCPClient.send_and_recv(socket, "join #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "leave #{room}")
      assert response == "#{cont.leader} has left the room #{room}"
      TCPClient.close(socket)
    end

    test "delete room by creator", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "delete #{room}")
      assert response == "Room #{room} deleted"
      TCPClient.close(socket)
    end

    test "non-creator cannot delete room", cont do
      {:ok, socket1} = TCPClient.connect(cont.port)
      {:ok, socket2} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket1, "login #{cont.leader}")
      TCPClient.send_and_recv(socket1, "create #{room}")
      TCPClient.send_and_recv(socket2, "login #{cont.user1}")
      TCPClient.send_and_recv(socket2, "join #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket2, "delete #{room}")
      assert response == "User unauthorized to perform this action"
      Enum.each([socket1, socket2], &TCPClient.close/1)
    end

    test "user cannot join room twice", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      TCPClient.send_and_recv(socket, "join #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "join #{room}")
      assert response == "User already joined the room"
      TCPClient.close(socket)
    end
  end

  describe "voting operations" do
    test "set topic in room", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      topic = "new topic"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "topic #{room}:#{topic}")
      assert response == "Room: #{room}. Topic changed to: #{topic}"
      TCPClient.close(socket)
    end

    test "cast vote in room", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "vote #{room}:5")
      assert response == "#{cont.leader} has voted"
      TCPClient.close(socket)
    end

    test "vote in non-existent room returns error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      TCPClient.send_and_recv(socket, "login #{cont.user1}")
      {:ok, response} = TCPClient.send_and_recv(socket, "vote nonexistent:5")
      assert response == "Room not found"
      TCPClient.close(socket)
    end

    test "invalid vote value returns error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      TCPClient.send_and_recv(socket, "create #{room}")
      {:ok, response} = TCPClient.send_and_recv(socket, "vote #{room}:invalid")
      assert response == "Invalid vote argument"
      TCPClient.close(socket)
    end
  end

  describe "protocol and error handling" do
    test "invalid command returns error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      {:ok, response} = TCPClient.send_and_recv(socket, "invalid_command")
      assert response == "Unknown request"
      TCPClient.close(socket)
    end

    test "malformed topic command returns error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      TCPClient.send_and_recv(socket, "login #{cont.leader}")
      {:ok, response} = TCPClient.send_and_recv(socket, "topic room_without_colon")
      assert response == "Unknown request"
      TCPClient.close(socket)
    end

    test "empty command returns error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      {:ok, response} = TCPClient.send_and_recv(socket, "")
      assert response == "Unknown request"
      TCPClient.close(socket)
    end

    test "connection remains active after error", cont do
      {:ok, socket} = TCPClient.connect(cont.port)
      TCPClient.send_and_recv(socket, "invalid_command")
      {:ok, response} = TCPClient.send_and_recv(socket, "list")
      assert response == "No active rooms"
      TCPClient.close(socket)
    end
  end

  describe "concurrent operations" do
    test "two users can create rooms simultaneously", cont do
      {:ok, socket1} = TCPClient.connect(cont.port)
      {:ok, socket2} = TCPClient.connect(cont.port)
      room1 = "Room1"
      room2 = "Room2"
      TCPClient.send_and_recv(socket1, "login #{cont.leader}")
      TCPClient.send_and_recv(socket2, "login #{cont.leader}")
      {:ok, resp1} = TCPClient.send_and_recv(socket1, "create #{room1}")
      {:ok, resp2} = TCPClient.send_and_recv(socket2, "create #{room2}")
      assert resp1 == "Room #{room1} created"
      assert resp2 == "Room #{room2} created"
      {:ok, list_resp} = TCPClient.send_and_recv(socket1, "list")
      assert String.contains?(list_resp, [room1, room2])
      Enum.each([socket1, socket2], &TCPClient.close/1)
    end

    test "two users can vote in the same room", cont do
      {:ok, socket1} = TCPClient.connect(cont.port)
      {:ok, socket2} = TCPClient.connect(cont.port)
      room = "Room1"
      TCPClient.send_and_recv(socket1, "login #{cont.leader}")
      TCPClient.send_and_recv(socket1, "create #{room}")
      TCPClient.send_and_recv(socket2, "login #{cont.user1}")
      TCPClient.send_and_recv(socket2, "join #{room}")
      {:ok, vote1} = TCPClient.send_and_recv(socket1, "vote #{room}:3")
      {:ok, vote2} = TCPClient.send_and_recv(socket2, "vote #{room}:5")
      assert vote1 == "#{cont.leader} has voted"
      assert vote2 == "#{cont.user1} has voted"
      Enum.each([socket1, socket2], &TCPClient.close/1)
    end
  end
end
