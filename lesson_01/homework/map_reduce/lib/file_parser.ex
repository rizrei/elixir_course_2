defmodule FileParser do
  @moduledoc """
  Parses file with fruits data
  """

  defmodule InvalidStringFormatError do
    defexception [:file, :line]

    @impl true
    def exception({file, line}) do
      %__MODULE__{file: file, line: line}
    end

    @impl true
    def message(%__MODULE__{line: line, file: file}) do
      "Invalid string format in file #{file}: #{line}"
    end
  end

  @spec parse!(String.t()) :: %{String.t() => integer()} | no_return()
  def parse!(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(&parse_str!(&1, file_path))
    |> Enum.into(%{})
  end

  @string_regex ~r/^\d+,(?<fruit>[a-z]+),(?<amount>\d+),\d+$/
  defp parse_str!(str, file_path) do
    case Regex.named_captures(@string_regex, str) do
      %{"amount" => amount, "fruit" => fruit} -> {fruit, String.to_integer(amount)}
      _ -> raise InvalidStringFormatError, {file_path, str}
    end
  end
end
