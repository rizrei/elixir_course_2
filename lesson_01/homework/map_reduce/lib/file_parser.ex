defmodule FileParser do
  defmodule InvalidStringFormatError do
    defexception [:message]
  end

  @type parse! :: %{String.t() => integer()} | no_return()
  def parse!(file_path) do
    do_parse!(file_path)
  end

  @type parse :: %{String.t() => integer()} | {:error, String.t()}
  def parse(file_path) do
    do_parse!(file_path)
  rescue
    e in File.Error -> {:error, "Failed to read file: #{e.path}"}
    e in InvalidStringFormatError -> {:error, e.message}
    e -> {:error, inspect(e)}
  end

  def do_parse!(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(&parse_str!/1)
    |> Enum.into(%{})
  end

  @string_regex ~r/^\d+,(?<fruit>[a-z]+),(?<amount>\d+),\d+$/
  def parse_str!(str) do
    case Regex.named_captures(@string_regex, str) do
      %{"amount" => amount, "fruit" => fruit} -> {fruit, String.to_integer(amount)}
      _ -> raise InvalidStringFormatError, "Invalid string format: #{str}"
    end
  end
end
