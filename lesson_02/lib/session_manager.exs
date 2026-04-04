defmodule SessionManager do
  defmodule Session do
    @type t :: %__MODULE__{
            username: String.t(),
            shard: non_neg_integer(),
            node: String.t()
          }

    defstruct [:username, :shard, :node]
  end

  @type state() :: [Session.t()]

  @spec start() :: Agent.on_start()
  def start(), do: Agent.start(fn -> [] end)

  @spec stop(pid()) :: :ok
  def stop(pid), do: Agent.stop(pid)

  @spec add_session(pid(), String.t()) :: :ok
  def add_session(manager_pid, username) do
    {shard, node} = ShardManager.settle(username)
    Agent.update(manager_pid, &[%Session{username: username, shard: shard, node: node} | &1])
  end

  @spec get_sessions(pid()) :: [Session.t()]
  def get_sessions(manager_pid), do: Agent.get(manager_pid, & &1)

  @spec get_session_by_name(pid(), String.t()) :: {:ok, Session.t()} | {:error, :not_found}
  def get_session_by_name(manager_pid, name) do
    Agent.get(manager_pid, &find_session(&1, name))
  end

  # function works inside Agent process
  @spec find_session([Session.t()], String.t()) :: {:ok, Session.t()} | {:error, :not_found}
  defp find_session(sessions, name) do
    Enum.find_value(sessions, {:error, :not_found}, &if(&1.username == name, do: {:ok, &1}))
  end
end
