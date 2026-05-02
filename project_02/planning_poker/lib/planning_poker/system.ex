defmodule PlanningPoker.System do
  use Supervisor

  alias PlanningPoker.Rooms.Room

  @spec start_link() :: Supervisor.on_start()
  def start_link(), do: Supervisor.start_link(__MODULE__, [])

  @impl true
  def init(_) do
    children = [
      {Registry, [keys: :unique, name: Room.Registry]},
      {PlanningPoker.PubSub, name: :pubsub},
      Room.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
