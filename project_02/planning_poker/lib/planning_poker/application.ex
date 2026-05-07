defmodule PlanningPoker.Application do
  use Application

  require Logger

  @impl true
  def start(_start_type, _args), do: PlanningPoker.System.start_link([])
end
