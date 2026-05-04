defmodule PlanningPoker.Rooms.Room do
  alias PlanningPoker.Users.User

  @enforce_keys [:name]
  defstruct [:name, :topic, users: %{}]

  @type t() :: %__MODULE__{
          name: String.t(),
          topic: String.t() | nil,
          users: %{User.t() => integer()}
        }

  @spec new(String.t()) :: t()
  def new(name), do: %__MODULE__{name: name}

  @spec member?(t(), User.t()) :: boolean()
  def member?(%{users: users}, user), do: is_map_key(users, user)

  @spec clear_votes(t()) :: t()
  def clear_votes(%{users: users} = room) do
    %{room | users: Map.new(users, fn {k, _} -> {k, nil} end)}
  end

  @spec change_topic(t(), String.t()) :: t()
  def change_topic(room, topic), do: %{room | topic: topic}

  @spec vote(t(), User.t(), integer()) :: t() | {:error, atom()}
  def vote(room, user, vote) when is_binary(vote) do
    case Integer.parse(vote) do
      {int_vote, ""} -> vote(room, user, int_vote)
      :error -> {:error, :invalid_vote}
    end
  end

  def vote(%{users: users}, user, _) when not is_map_key(users, user),
    do: {:error, :user_not_found}

  def vote(%{users: users} = room, user, vote), do: %{room | users: Map.put(users, user, vote)}

  @spec join(t(), User.t()) :: t() | {:error, atom()}
  def join(%{users: users}, user) when is_map_key(users, user),
    do: {:error, :user_already_joined}

  def join(%{users: users} = room, user), do: %{room | users: Map.put(users, user, nil)}

  @spec leave(t(), User.t()) :: t() | {:error, atom()}
  def leave(%{users: users}, user) when not is_map_key(users, user), do: {:error, :user_not_found}
  def leave(%{users: users} = room, user), do: %{room | users: Map.delete(users, user)}

  defimpl String.Chars do
    def to_string(%{name: name, topic: topic} = room) do
      """
      Room: #{name}
      Topic: #{topic}
      Votes:
      #{room_votes(room)}
      """
    end

    defp room_votes(%{users: users}) do
      users
      |> Enum.map_join("\n", fn {%{name: name}, vote} -> String.trim("#{name} #{vote}") end)
    end
  end
end
