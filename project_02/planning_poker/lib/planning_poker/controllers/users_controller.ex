defmodule PlanningPoker.Controllers.UsersController do
  alias PlanningPoker.Users
  alias PlanningPoker.Sockets.Socket
  alias PlanningPoker.Serializers.UsersSerializer

  @spec login(Socket.t(), String.t()) :: {:ok, {Socket.t(), String.t()}}
  def login(socket, username) do
    case Users.get_user_by_name(username) do
      {:ok, user} ->
        {:ok, {Socket.login(socket, user), UsersSerializer.serialize(:login, user)}}

      {:error, :user_not_found} ->
        {:ok, {socket, "User #{username} not found"}}
    end
  end

  @spec logout(Socket.t()) :: {:ok, {Socket.t(), String.t()}}
  def logout(%{user: user} = socket) do
    with :ok <- Socket.authenticate_user(socket),
         %Socket{} = socket <- Socket.logout(socket) do
      {:ok, {socket, UsersSerializer.serialize(:logout, user)}}
    end
  end
end
