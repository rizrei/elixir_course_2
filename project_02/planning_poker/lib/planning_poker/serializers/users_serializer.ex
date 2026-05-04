defmodule PlanningPoker.Serializers.UsersSerializer do
  alias PlanningPoker.Users.User

  @spec serialize(action :: atom(), User.t()) :: String.t()
  def serialize(:login, %User{name: name, role: role}) do
    "Logged in, name: #{name} role: #{role}"
  end

  def serialize(:logout, nil), do: "User already logged out"
  def serialize(:logout, %User{name: name}), do: "Logged out, name: #{name}"
end
