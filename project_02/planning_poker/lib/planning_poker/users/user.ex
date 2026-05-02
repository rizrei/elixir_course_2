defmodule PlanningPoker.Users.User do
  @type role() :: :leader | :participant

  @type t() :: %__MODULE__{
          id: integer(),
          name: String.t(),
          role: role()
        }

  defstruct [:id, :name, :role]

  @spec leader?(t()) :: boolean()
  def leader?(%{role: role}), do: role == :leader
end
