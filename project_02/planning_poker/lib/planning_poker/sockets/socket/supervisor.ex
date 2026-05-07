defmodule PlanningPoker.Sockets.Socket.Supervisor do
  use Supervisor

  alias PlanningPoker.Sockets.Socket

  @spec start_link(:inet.port_number()) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, port} = Application.fetch_env!(:planning_poker, :port) |> listen_socket()

    [
      :poolboy.child_spec(
        :worker,
        [
          name: {:local, Socket.Pool},
          worker_module: Socket.Server,
          size: Application.fetch_env!(:planning_poker, :pool_size),
          max_overflow: 0
        ],
        port: port
      )
    ]
    |> Supervisor.init(strategy: :one_for_one)
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
