defmodule PlanningPoker.Application do
  use Application

  alias PlanningPoker.Rooms.Room
  alias PlanningPoker.Sockets.Socket

  @impl true
  def start(_start_type, _args) do
    [
      {Registry, [keys: :unique, name: Room.Registry]},
      {PlanningPoker.PubSub, name: :pubsub},
      Room.Supervisor,
      Socket.Supervisor
    ]
    |> Supervisor.start_link(strategy: :one_for_one)
  end
end
