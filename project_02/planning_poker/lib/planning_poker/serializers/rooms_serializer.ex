defmodule PlanningPoker.Serializers.RoomsSerializer do
  @spec serialize(action :: atom(), term()) :: String.t()
  def serialize(:create, room_name), do: "Room #{room_name} created"

  def serialize(:delete, room_name), do: "Room #{room_name} deleted"

  def serialize(:index, []), do: "No active rooms"
  def serialize(:index, list_rooms), do: Enum.join(["Rooms:" | list_rooms], "\n")

  def serialize(:show, room), do: to_string(room)

  def serialize(:join, {room_name, user}) do
    "#{user.name} #{user.role} has joined to the room #{room_name}"
  end

  def serialize(:leave, {room_name, user}) do
    "#{user.name} has left the room #{room_name}"
  end

  def serialize(:change_topic, {room_name, new_topic}) do
    "Room: #{room_name}. Topic changed to: #{new_topic}"
  end

  def serialize(:vote, user), do: "#{user.name} has voted"
end
