defmodule Tree do
  @moduledoc """
  Builds tree of processes for map-reduce solution
  """

  defmodule Chunk do
    @moduledoc """
    Chunk of mappers or reducers, used to build tree level by level
    """

    alias Tree

    defstruct [
      :first_item_id,
      :last_item_id,
      items: [],
      items_count: 0
    ]

    @type t :: %__MODULE__{
            first_item_id: integer() | nil,
            last_item_id: integer() | nil,
            items: [Tree.reducer() | Tree.mapper()],
            items_count: non_neg_integer()
          }

    @spec add_item(t(), Tree.reducer() | Tree.mapper()) :: t()
    def add_item(chunk, {:reducer, {min, max}, _} = node) do
      %{
        chunk
        | first_item_id: min(chunk.first_item_id, min),
          last_item_id: max,
          items: [node | chunk.items],
          items_count: chunk.items_count + 1
      }
    end

    def add_item(chunk, {:mapper, id, _} = node) do
      %{
        chunk
        | first_item_id: min(chunk.first_item_id, id),
          last_item_id: max(chunk.last_item_id || id, id),
          items: [node | chunk.items],
          items_count: chunk.items_count + 1
      }
    end

    @spec build(t()) :: Tree.reducer()
    def build(%{items: [{:reducer, _, _} = node]}), do: node

    def build(%{first_item_id: first, last_item_id: last, items: items}) do
      {:reducer, {first, last}, Enum.reverse(items)}
    end
  end

  defstruct [:level, :files, chunks: []]

  @type t :: %__MODULE__{
          level: pos_integer() | :infinity,
          files: [String.t()],
          chunks: [Chunk.t()]
        }

  @type mapper_id() :: integer()
  @type reducer_id() :: {integer(), integer()}
  @type mapper() :: {:mapper, mapper_id(), String.t()}
  @type reducer() :: {:reducer, reducer_id(), [mapper()] | [reducer()]}

  @spec new([String.t()], pos_integer() | :infinity) :: t()
  def new(files, 1), do: %__MODULE__{level: :infinity, files: files}
  def new(files, level), do: %__MODULE__{level: level, files: files}

  @spec build(t()) :: reducer()
  def build(%{files: files} = tree) do
    files
    |> Enum.with_index(&{:mapper, &2 + 1, &1})
    |> do_build(tree)
  end

  defp do_build({:reducer, _, _} = node, _), do: node

  defp do_build([], %{level: level, files: files} = tree) do
    new_tree = new(files, level)
    tree |> nodes() |> do_build(new_tree)
  end

  defp do_build([h | t], tree) do
    tree = add_node(tree, h)
    do_build(t, tree)
  end

  defp add_node(%{chunks: []} = tree, node) do
    %{tree | chunks: [Chunk.add_item(%Chunk{}, node)]}
  end

  defp add_node(%{level: level, chunks: [%{items_count: level} | _] = chunks} = tree, node) do
    %{tree | chunks: [Chunk.add_item(%Chunk{}, node) | chunks]}
  end

  defp add_node(%{chunks: [chunk | t]} = tree, node) do
    %{tree | chunks: [Chunk.add_item(chunk, node) | t]}
  end

  defp nodes(%{chunks: chunks}) do
    chunks
    |> Enum.map(&Chunk.build/1)
    |> Enum.reverse()
    |> then(fn
      [node] -> node
      nodes -> nodes
    end)
  end
end
