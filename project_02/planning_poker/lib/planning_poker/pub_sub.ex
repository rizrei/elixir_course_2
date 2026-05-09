defmodule PlanningPoker.PubSub do
  @spec start_link([{:name, String.t()}]) :: {:ok, pid()} | {:error, term()}
  def start_link(options) do
    Registry.start_link(keys: :duplicate, name: Keyword.fetch!(options, :name))
  end

  @spec subscribe(atom(), String.t()) :: {:ok, pid()} | {:error, term()}
  def subscribe(pubsub, topic) do
    Registry.register(pubsub, topic, nil)
  end

  @spec broadcast(atom(), String.t(), term()) :: :ok
  def broadcast(pubsub, topic, msg) do
    Registry.dispatch(pubsub, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)
  end

  def child_spec(options) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [options]}
    }
  end
end
