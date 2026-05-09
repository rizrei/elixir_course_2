defmodule PlanningPoker.Sockets.Socket.Server do
  use GenServer

  alias PlanningPoker.Sockets.Socket

  def start_link(args), do: GenServer.start_link(__MODULE__, Keyword.fetch!(args, :port))

  @impl true
  def init(port) do
    {:ok, %Socket{port: port}, {:continue, :listen_socket}}
  end

  @impl true
  def handle_continue(:listen_socket, %{port: port} = socket) do
    case :gen_tcp.accept(port) do
      {:ok, socket_pid} ->
        send(self(), :loop)
        {:noreply, %{socket | socket_pid: socket_pid}}

      {:error, _} = error ->
        {:stop, error, socket}
    end
  end

  @impl true
  def handle_info(:loop, %{socket_pid: socket_pid} = socket) do
    case :gen_tcp.recv(socket_pid, 0, 1000) do
      {:ok, data} ->
        {socket, response} = Socket.handle_request(socket, String.trim(data))
        :gen_tcp.send(socket_pid, response <> "\n")
        send(self(), :loop)
        {:noreply, socket}

      {:error, :timeout} ->
        send(self(), :loop)
        {:noreply, socket}

      {:error, _error} ->
        :gen_tcp.close(socket_pid)
        socket = Socket.logout(socket)
        {:noreply, socket, {:continue, :listen_socket}}
    end
  end
end
