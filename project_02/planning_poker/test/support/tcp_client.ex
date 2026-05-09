defmodule PlanningPoker.TCPClient do
  @moduledoc "TCP client utility for integration testing"

  def connect(port, timeout \\ 5000) do
    case :gen_tcp.connect(~c"localhost", port, [:binary, {:active, false}], timeout) do
      {:ok, socket} -> {:ok, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  def send_command(socket, command), do: :gen_tcp.send(socket, command <> "\n")

  def recv_response(socket, timeout \\ 1000) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, data} -> {:ok, String.trim(data)}
      {:error, reason} -> {:error, reason}
    end
  end

  def close(socket), do: :gen_tcp.close(socket)

  def send_and_recv(socket, command, timeout \\ 1000) do
    with :ok <- send_command(socket, command),
         {:ok, response} <- recv_response(socket, timeout) do
      {:ok, response}
    else
      error -> error
    end
  end
end
