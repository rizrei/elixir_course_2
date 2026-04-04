defmodule ShardManager do
  defmodule Shard do
    @type t :: %__MODULE__{
            node: String.t(),
            range: Range.t()
          }

    defstruct [:node, :range]
  end

  defmodule State do
    @type t :: %__MODULE__{
            num_shards: pos_integer(),
            shards: [Shard.t()]
          }

    defstruct [:num_shards, :shards]

    @spec new([String.t()], pos_integer()) :: t()
    def new(nodes, num_shards) do
      1..num_shards
      |> Stream.chunk_every(ceil(num_shards / length(nodes)))
      |> Stream.map(&(List.first(&1)..List.last(&1)))
      |> Stream.zip_with(nodes, &%Shard{range: &1, node: &2})
      |> Enum.to_list()
      |> then(&%__MODULE__{num_shards: num_shards, shards: &1})
    end

    @spec get_node(t(), non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found}
    def get_node(%State{shards: shards}, shard_num) do
      Enum.find_value(shards, {:error, :not_found}, fn %Shard{node: node, range: range} ->
        if shard_num in range, do: {:ok, node}
      end)
    end
  end

  def start(), do: start(["node-1", "node-2", "node-3", "node-4"], 32)

  @spec start([String.t()], pos_integer()) :: Agent.on_start()
  def start(nodes, num_shards) do
    Agent.start(fn -> State.new(nodes, num_shards) end, name: __MODULE__)
  end

  @spec get_node(non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found}
  def get_node(shard), do: Agent.get(__MODULE__, &State.get_node(&1, shard))

  @spec settle(String.t()) :: {non_neg_integer(), String.t()}
  def settle(username) do
    num_shards = Agent.get(__MODULE__, & &1.num_shards)
    shard = :erlang.phash2(username, num_shards) + 1
    {:ok, node} = get_node(shard)
    {shard, node}
  end
end
