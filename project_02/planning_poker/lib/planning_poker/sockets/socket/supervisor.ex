defmodule PlanningPoker.Sockets.Socket.Supervisor do
  use Supervisor

  alias PlanningPoker.Sockets.Socket

  @spec start_link(:inet.port_number()) :: Supervisor.on_start()
  def start_link(port) do
    Supervisor.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    {:ok, socket} = listen_socket(port)

    children = [
      {Socket.Server, socket}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp listen_socket(port) do
    options = [
      :binary,
      {:active, false},
      {:packet, :line},
      {:reuseaddr, true}
    ]

    :gen_tcp.listen(port, options)
  end
end
