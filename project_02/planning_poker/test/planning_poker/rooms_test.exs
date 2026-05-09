defmodule PlanningPoker.RoomsTest do
  use ExUnit.Case

  alias PlanningPoker.Rooms
  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Users.User
  alias PlanningPoker.Rooms.Room.Supervisor, as: RoomSupervisor

  setup_all do
    leader = %User{id: 1, name: "Alice", role: :leader}
    participant = %User{id: 2, name: "Bob", role: :participant}
    participant2 = %User{id: 3, name: "Charlie", role: :participant}

    {:ok, leader: leader, participant: participant, participant2: participant2}
  end

  setup do
    on_exit(fn -> Enum.map(Rooms.list(), &RoomSupervisor.stop_room/1) end)
  end

  describe "list/0" do
    test "returns all room names sorted alphabetically", %{leader: leader} do
      Rooms.create("RoomZ", leader)
      Rooms.create("RoomA", leader)
      Rooms.create("RoomB", leader)

      assert ["RoomA", "RoomB", "RoomZ"] == Rooms.list()
    end
  end

  describe "show/2" do
    test "returns room details for authorized member", %{leader: leader} do
      Rooms.create("ShowRoom1", leader)
      result = Rooms.show("ShowRoom1", leader)

      assert %Room{name: "ShowRoom1"} = result
      assert is_map_key(result.users, leader)
    end

    test "prevents unauthorized non-member from seeing room", %{
      leader: leader,
      participant: participant
    } do
      Rooms.create("ShowRoom3", leader)

      assert {:error, :unauthorized_user} = Rooms.show("ShowRoom3", participant)
    end

    test "returns error for non-existent room", %{participant: participant} do
      assert {:error, :room_not_found} = Rooms.show("NonExistent", participant)
    end
  end

  describe "create/2" do
    test "creates a new room with given name", %{leader: leader} do
      assert :ok == Rooms.create("CreateRoom1", leader)
      assert %Room{name: "CreateRoom1", users: users} = Rooms.show("CreateRoom1", leader)
      assert is_map_key(users, leader)
    end

    test "when room with current name already exists", %{leader: leader} do
      Rooms.create("CreateRoom2", leader)
      assert {:error, :room_already_started} = Rooms.create("CreateRoom2", leader)
    end

    test "prevents non-leader from creating room", %{participant: participant} do
      assert {:error, :unauthorized_user} = Rooms.create("CreateRoom3", participant)
    end

    test "adds creator as member of new room", %{leader: leader} do
      Rooms.create("CreateRoom4", leader)
      room = Rooms.show("CreateRoom4", leader)

      assert Room.member?(room, leader)
    end
  end

  describe "delete/2" do
    test "leader can delete room", %{leader: leader} do
      Rooms.create("DeleteRoom1", leader)
      assert :ok = Rooms.delete("DeleteRoom1", leader)
      assert [] == Rooms.list()
    end

    test "prevents non-leader from deleting room", %{leader: leader, participant: participant} do
      Rooms.create("DeleteRoom2", leader)

      assert {:error, :unauthorized_user} = Rooms.delete("DeleteRoom2", participant)
    end
  end

  describe "join/2" do
    test "participant can join existing room", %{leader: leader, participant: participant} do
      Rooms.create("JoinRoom1", leader)
      assert :ok = Rooms.join("JoinRoom1", participant)
      assert "JoinRoom1" |> Rooms.show(participant) |> Room.member?(participant)
    end

    test "cannot join non-existent room", %{participant: participant} do
      assert {:error, :room_not_found} = Rooms.join("NonExistent", participant)
    end

    test "user joining twice returns error", %{leader: leader, participant: participant} do
      Rooms.create("JoinRoom4", leader)
      Rooms.join("JoinRoom4", participant)

      assert {:error, :user_already_joined} = Rooms.join("JoinRoom4", participant)
    end
  end

  describe "leave/2" do
    test "member can leave room", %{leader: leader, participant: participant} do
      Rooms.create("LeaveRoom1", leader)
      Rooms.join("LeaveRoom1", participant)

      assert :ok = Rooms.leave("LeaveRoom1", participant)
      assert %Room{users: users} = Rooms.show("LeaveRoom1", leader)
      refute is_map_key(users, participant)
    end

    test "prevents non-member from leaving", %{leader: leader, participant: participant} do
      Rooms.create("LeaveRoom3", leader)

      assert {:error, :unauthorized_user} = Rooms.leave("LeaveRoom3", participant)
    end

    test "cannot leave non-existent room", %{participant: participant} do
      assert {:error, :room_not_found} = Rooms.leave("NonExistent", participant)
    end
  end

  describe "vote/3" do
    test "member can vote in room", %{leader: leader, participant: participant} do
      Rooms.create("VoteRoom1", leader)
      Rooms.join("VoteRoom1", participant)

      assert :ok = Rooms.vote("VoteRoom1", participant, "5")
      assert %Room{users: users} = Rooms.show("VoteRoom1", participant)
      assert users[participant] == 5
    end

    test "prevents non-member from voting", %{leader: leader, participant: participant} do
      Rooms.create("VoteRoom3", leader)

      assert {:error, :unauthorized_user} = Rooms.vote("VoteRoom3", participant, "5")
    end

    test "cannot vote in non-existent room", %{participant: participant} do
      assert {:error, :room_not_found} = Rooms.vote("NonExistent", participant, "5")
    end

    test "handles invalid vote format", %{leader: leader, participant: participant} do
      Rooms.create("VoteRoom5", leader)
      Rooms.join("VoteRoom5", participant)

      assert {:error, :invalid_vote} = Rooms.vote("VoteRoom5", participant, "not_a_number")
    end
  end

  describe "change_topic/3" do
    test "leader member can change topic", %{leader: leader} do
      Rooms.create("TopicRoom1", leader)

      assert :ok = Rooms.change_topic("TopicRoom1", leader, "New Topic")
      room = Rooms.show("TopicRoom1", leader)
      assert room.topic == "New Topic"
    end

    test "non-leader member cannot change topic", %{leader: leader, participant: participant} do
      Rooms.create("TopicRoom2", leader)
      Rooms.join("TopicRoom2", participant)

      assert {:error, :unauthorized_user} =
               Rooms.change_topic("TopicRoom2", participant, "New Topic")
    end

    test "leader who is not a member cannot change topic", %{leader: leader} do
      other_leader = %User{id: 10, name: "Dave", role: :leader}
      Rooms.create("TopicRoom3", other_leader)

      assert {:error, :unauthorized_user} = Rooms.change_topic("TopicRoom3", leader, "New Topic")
    end

    test "topic is updated in room after change", %{leader: leader} do
      Rooms.create("TopicRoom4", leader)
      Rooms.change_topic("TopicRoom4", leader, "Feature Request")
      room = Rooms.show("TopicRoom4", leader)

      assert room.topic == "Feature Request"
    end

    test "clears votes when topic changes", %{leader: leader, participant: participant} do
      Rooms.create("TopicRoom5", leader)
      Rooms.join("TopicRoom5", participant)
      Rooms.vote("TopicRoom5", participant, "5")
      Rooms.change_topic("TopicRoom5", leader, "New Topic")
      room = Rooms.show("TopicRoom5", leader)

      assert room.users[participant] == nil
    end

    test "cannot change topic in non-existent room", %{leader: leader} do
      assert {:error, :room_not_found} = Rooms.change_topic("NonExistent", leader, "Topic")
    end
  end
end
