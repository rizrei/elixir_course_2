defmodule PlanningPoker.Sockets.Socket.RouterTest do
  use ExUnit.Case
  doctest PlanningPoker.Sockets.Socket.Router

  alias PlanningPoker.Sockets.Socket.Router
  alias PlanningPoker.Controllers.{UsersController, RoomsController}

  describe "route/1 - user commands" do
    test "routes login command" do
      assert {:ok, {UsersController, :login, ["alice"]}} = Router.route("login alice")
    end

    test "routes logout command" do
      assert {:ok, {UsersController, :logout, []}} = Router.route("logout")
    end
  end

  describe "route/1 - room list commands" do
    test "routes list_rooms command" do
      assert {:ok, {RoomsController, :index, []}} = Router.route("list")
    end

    test "routes show_room command" do
      assert {:ok, {RoomsController, :show, ["planning"]}} = Router.route("show planning")
    end
  end

  describe "route/1 - room management commands" do
    test "routes create_room command" do
      assert {:ok, {RoomsController, :create, ["sprint1"]}} = Router.route("create sprint1")
    end

    test "routes delete_room command" do
      assert {:ok, {RoomsController, :delete, ["sprint1"]}} = Router.route("delete sprint1")
    end
  end

  describe "route/1 - room participation commands" do
    test "routes join command" do
      assert {:ok, {RoomsController, :join, ["sprint1"]}} = Router.route("join sprint1")
    end

    test "routes leave command" do
      assert {:ok, {RoomsController, :leave, ["sprint1"]}} = Router.route("leave sprint1")
    end
  end

  describe "route/1 - room voting commands" do
    test "routes change_topic command" do
      assert {:ok, {RoomsController, :change_topic, ["room1", "new topic"]}} =
               Router.route("topic room1:new topic")
    end

    test "returns error for malformed change_topic command" do
      assert {:error, :invalid_route} = Router.route("topic room1")
    end

    test "routes vote command" do
      assert {:ok, {RoomsController, :vote, ["room1", "5"]}} = Router.route("vote room1:5")
    end

    test "returns error for malformed vote command" do
      {:error, error} = Router.route("vote room1")

      assert error == :invalid_route
    end
  end

  describe "route/1 - invalid commands" do
    test "returns error for empty command" do
      assert {:error, :invalid_route} = Router.route("")
    end

    test "returns error for gibberish" do
      assert {:error, :invalid_route} = Router.route("qwerty asdf zxcv")
    end
  end
end
