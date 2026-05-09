defmodule PlanningPoker.Users do
  alias PlanningPoker.Users.User

  def users_topic(), do: "users"

  def get_users() do
    [
      %User{id: 1, name: "Yura", role: :participant},
      %User{id: 2, name: "Bob", role: :participant},
      %User{id: 3, name: "Helen", role: :leader},
      %User{id: 4, name: "Kate", role: :participant}
    ]
  end

  def get_user_by_name(name) do
    get_users()
    |> Enum.find(&(&1.name == name))
    |> then(&((&1 && {:ok, &1}) || {:error, :user_not_found}))
  end
end
