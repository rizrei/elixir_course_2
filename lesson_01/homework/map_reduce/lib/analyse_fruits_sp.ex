defmodule AnalyseFruitsSP do
  @moduledoc """
  Single process solution
  """

  alias FileParser.InvalidStringFormatError

  @type result :: %{String.t() => integer()}

  @spec start() :: result
  def start() do
    start([
      "./data/data_1.csv",
      "./data/data_2.csv",
      "./data/data_3.csv"
    ])
  end

  @spec start([String.t()]) :: result
  def start(files) do
    files
    |> Enum.map(&FileParser.parse!/1)
    |> Enum.reduce(%{}, &merge/2)
  rescue
    e in [File.Error, InvalidStringFormatError] -> {:error, apply(e.__struct__, :message, [e])}
    e -> {:error, inspect(e)}
  end

  defp merge(m1, m2), do: Map.merge(m1, m2, fn _k, v1, v2 -> v1 + v2 end)
end
