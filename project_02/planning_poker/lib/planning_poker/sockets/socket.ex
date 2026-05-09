defmodule PlanningPoker.Sockets.Socket do
  alias PlanningPoker.PubSub
  alias PlanningPoker.Users
  alias PlanningPoker.Users.User
  alias PlanningPoker.Sockets.Socket.Router
  alias PlanningPoker.Serializers.ErrorsSerializer

  defstruct [:socket_pid, :port, :user]

  @type t() :: %__MODULE__{
          socket_pid: pid(),
          port: integer(),
          user: User.t() | nil
        }

  @spec handle_request(t(), String.t()) :: {t(), String.t()}
  def handle_request(socket, request) do
    with {:ok, {controller, action, args}} <- Router.route(request),
         {:ok, {socket, msg}} <- apply(controller, action, [socket | args]) do
      {socket, msg <> "\n"}
    else
      {:error, _} = error -> {socket, ErrorsSerializer.serialize(error)}
    end
  end

  @spec login(t(), User.t()) :: t()
  def login(socket, user), do: %{socket | user: user}

  @spec logout(t()) :: t()
  def logout(%{user: %User{} = user} = socket) do
    PubSub.broadcast(:pubsub, Users.users_topic(), {:user_logout, user})
    %{socket | user: nil}
  end

  def logout(socket), do: socket

  @spec authenticate_user(t()) :: :ok | {:error, :unauthenticated_user}
  def authenticate_user(%{user: %User{}}), do: :ok
  def authenticate_user(_), do: {:error, :unauthenticated_user}
end
