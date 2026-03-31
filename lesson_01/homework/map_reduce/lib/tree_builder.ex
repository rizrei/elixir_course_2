defmodule TreeBuilder do
  @moduledoc """
  Builds a tree of mappers and reducers for MapReduce solution
  """

  @type mapper_id() :: integer()
  @type reducer_id() :: {integer(), integer()}
  @type mapper() :: {:mapper, mapper_id(), String.t()}
  @type reducer() :: {:reducer, reducer_id(), [mapper()] | [reducer()]}

  @spec build([String.t()], pos_integer()) :: reducer()
  def build(files, per_level) when per_level == 1 or length(files) <= per_level do
    nodes =
      files
      |> Enum.with_index(fn fname, idx -> {:mapper, idx + 1, fname} end)

    {:reducer, build_chunk_id(nodes), nodes}
  end

  def build(files, per_level) do
    files
    |> Enum.with_index(fn fname, idx -> {:mapper, idx + 1, fname} end)
    |> Enum.chunk_every(per_level)
    |> Enum.map(&{:reducer, build_chunk_id(&1), &1})
    |> do_build(per_level)
  end

  defp do_build([{:reducer, _, _} = node], _), do: node

  defp do_build(nodes, per_level) when length(nodes) < per_level do
    {:reducer, build_chunk_id(nodes), nodes}
  end

  defp do_build(nodes, per_level) do
    nodes
    |> Enum.chunk_every(per_level)
    |> chunk_reducer(per_level, [])
    |> do_build(per_level)
  end

  defp chunk_reducer([], _, acc), do: Enum.reverse(acc)

  defp chunk_reducer([chunk | chunks], per_level, acc) when length(chunk) < per_level do
    chunk_reducer(chunks, per_level, Enum.reduce(chunk, acc, &[&1 | &2]))
  end

  defp chunk_reducer([chunk | chunks], per_level, acc) do
    chunk_reducer(chunks, per_level, [{:reducer, build_chunk_id(chunk), chunk} | acc])
  end

  defp build_chunk_id(chunk) do
    case {List.first(chunk), List.last(chunk)} do
      {{:mapper, min, _}, {:mapper, max, _}} -> {min, max}
      {{:reducer, {min, _}, _}, {:reducer, {_, max}, _}} -> {min, max}
    end
  end
end
