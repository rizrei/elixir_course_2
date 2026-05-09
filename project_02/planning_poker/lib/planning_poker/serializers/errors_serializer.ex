defmodule PlanningPoker.Serializers.ErrorsSerializer do
  def serialize({:error, :room_not_found}) do
    "Room not found"
  end

  def serialize({:error, :user_not_found}) do
    "User not found"
  end

  def serialize({:error, :unauthorized_user}) do
    "User unauthorized to perform this action"
  end

  def serialize({:error, :unauthenticated_user}) do
    "User must be authenticated to perform this action"
  end

  def serialize({:error, :user_already_joined}) do
    "User already joined the room"
  end

  def serialize({:error, :only_leader_can_change_topic}) do
    "Only leader can change room topic"
  end

  def serialize({:error, :only_leader_can_start_room}) do
    "Only leader can start the room"
  end

  def serialize({:error, :room_already_started}) do
    "Room already started"
  end

  def serialize({:error, :invalid_vote}) do
    "Invalid vote argument"
  end

  def serialize({:error, :invalid_route}) do
    "Unknown request"
  end

  def serialize({:error, msg}) do
    "Error: #{inspect(msg)}"
  end
end
