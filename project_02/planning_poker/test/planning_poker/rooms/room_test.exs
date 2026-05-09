defmodule PlanningPoker.Rooms.RoomTest do
  use ExUnit.Case

  doctest PlanningPoker.Rooms.Room

  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Users.User

  setup do
    user1 = %User{id: 1, name: "Alice", role: :participant}
    user2 = %User{id: 2, name: "Bob", role: :participant}
    user3 = %User{id: 3, name: "Charlie", role: :leader}

    {:ok, user1: user1, user2: user2, user3: user3}
  end

  describe "new/1" do
    test "creates a new room with given name" do
      room = Room.new("Planning")
      assert room.name == "Planning"
      assert room.topic == nil
      assert room.users == %{}
    end
  end

  describe "member?/2" do
    test "returns true if user is in room", %{user1: user1} do
      assert Room.new("Test") |> Room.join(user1) |> Room.member?(user1)
    end

    test "returns false if user is not in room", %{user1: user1, user2: _user2} do
      room = Room.new("Test")
      refute Room.member?(room, user1)
    end
  end

  describe "join/2" do
    test "adds user to room", %{user1: user1} do
      room = Room.new("Test") |> Room.join(user1)
      assert Room.member?(room, user1)
      assert room.users[user1] == nil
    end

    test "returns error if user already joined", %{user1: user1} do
      room = Room.new("Test") |> Room.join(user1)

      assert {:error, :user_already_joined} = Room.join(room, user1)
    end
  end

  describe "leave/2" do
    test "removes user from room", %{user1: user1} do
      room = Room.new("Test") |> Room.join(user1) |> Room.leave(user1)

      refute Room.member?(room, user1)
    end

    test "returns error if user not in room", %{user1: user1} do
      assert {:error, :user_not_found} = Room.new("Test") |> Room.leave(user1)
    end
  end

  describe "vote/3" do
    test "records vote for user", %{user1: user1} do
      room = Room.new("Test") |> Room.join(user1) |> Room.vote(user1, 5)

      assert room.users[user1] == 5
    end

    test "parses string votes to integers", %{user1: user1} do
      room = Room.new("Test") |> Room.join(user1) |> Room.vote(user1, "5")

      assert room.users[user1] == 5
    end

    test "returns error for invalid vote", %{user1: user1} do
      room = Room.new("Test") |> Room.join(user1)

      assert {:error, :invalid_vote} = Room.vote(room, user1, "not_a_number")
    end

    test "returns error if user not in room", %{user1: user1} do
      assert {:error, :user_not_found} = Room.new("Test") |> Room.vote(user1, 5)
    end
  end

  describe "clear_votes/1" do
    test "clears all votes but keeps users", %{user1: user1, user2: user2} do
      room =
        Room.new("Test")
        |> Room.join(user1)
        |> Room.join(user2)
        |> Room.vote(user1, 5)
        |> Room.vote(user2, 8)
        |> Room.clear_votes()

      assert room.users[user1] == nil
      assert room.users[user2] == nil
    end
  end

  describe "change_topic/2" do
    test "updates room topic" do
      room = Room.new("Test") |> Room.change_topic("New Feature")

      assert room.topic == "New Feature"
    end
  end

  describe "String.Chars protocol" do
    test "converts room to string representation", %{user1: user1, user2: user2} do
      str =
        Room.new("Planning")
        |> Room.join(user1)
        |> Room.join(user2)
        |> Room.vote(user1, 5)
        |> to_string()

      assert String.contains?(str, "Planning")
      assert String.contains?(str, "Alice 5")
      assert String.contains?(str, "Bob")
    end
  end
end
