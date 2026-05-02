defmodule PlanningPoker.Rooms.Room do
  alias PlanningPoker.Users.User

  @type t() :: %__MODULE__{
          name: String.t(),
          users: %MapSet{:map => %{User.t() => true}}
        }

  defstruct [:name, users: MapSet.new()]

  @spec new(String.t()) :: t()
  def new(name), do: %__MODULE__{name: name}

  @spec join(t(), User.t()) :: t() | {:error, atom()}
  def join(%{users: users} = room, user) do
    if MapSet.member?(users, user) do
      {:error, :user_already_joined}
    else
      %{room | users: MapSet.put(users, user)}
    end
  end

  @spec leave(t(), User.t()) :: t() | {:error, atom()}
  def leave(%{users: users} = room, user) do
    if MapSet.member?(users, user) do
      %{room | users: MapSet.delete(users, user)}
    else
      {:error, :user_not_found}
    end
  end
end
