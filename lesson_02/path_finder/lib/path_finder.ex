defmodule PathFinder do
  defmodule State do
    @moduledoc """
    State of GenServer, contains graph and data file path
    """
    defstruct [:graph, :data_file]

    @type t :: %__MODULE__{
            graph: Graph.t(),
            data_file: String.t()
          }

    @spec build_graph(t()) :: t()
    def build_graph(%__MODULE__{data_file: data_file} = state) do
      data_file
      |> File.stream!()
      |> CSV.decode!(headers: true, validate_row_length: true)
      |> Stream.map(&parse_distance/1)
      |> Enum.reduce(Graph.new(), &add_edge(&2, &1))
      |> then(&%{state | graph: &1})
    end

    @spec get_route(t(), String.t(), String.t()) ::
            {:ok, [String.t()], non_neg_integer()} | {:error, :no_route}
    def get_route(%State{graph: graph}, from_city, to_city) do
      case Graph.get_shortest_path(graph, from_city, to_city) do
        [_ | _] = route -> {:ok, {route, get_distance(graph, route)}}
        _ -> {:error, :no_route}
      end
    end

    defp add_edge(graph, %{"CityFrom" => city1, "CityTo" => city2, "Distance" => distance}) do
      graph
      |> Graph.add_edge(city1, city2, weight: distance)
      |> Graph.add_edge(city2, city1, weight: distance)
    end

    defp parse_distance(map), do: Map.update!(map, "Distance", &String.to_integer/1)

    defp get_distance(graph, route) do
      route
      |> Stream.chunk_every(2, 1, :discard)
      |> Stream.map(fn [city1, city2] -> Graph.edge(graph, city1, city2) end)
      |> Stream.map(fn %Graph.Edge{weight: weight} -> weight end)
      |> Enum.sum()
    end
  end

  @moduledoc """
  GenServer that builds graph of cities and distances between them from data file and finds shortest path between cities on demand
  """

  use GenServer

  require Logger

  @type city() :: String.t()
  @type distance() :: integer
  @type route() :: {[city()], distance()}

  @server_name __MODULE__
  @data_file "./data/cities.csv"

  # Module API

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(__MODULE__, @data_file, name: @server_name)
  end

  def stop(), do: GenServer.stop(@server_name)

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(data_file) do
    GenServer.start_link(__MODULE__, data_file, name: @server_name)
  end

  @spec get_route(city(), city()) :: {:ok, route()} | {:error, term()}
  def get_route(from_city, to_city) do
    GenServer.call(@server_name, {:get_route, from_city, to_city})
  end

  @spec reload_data() :: :ok
  def reload_data(), do: GenServer.cast(@server_name, :reload_data)

  # GenServer callbacks

  @impl true
  def init(data_file), do: {:ok, %State{data_file: data_file}, {:continue, :build_graph}}

  @impl true
  def handle_continue(:build_graph, state) do
    Logger.info("Building graph from data file #{state.data_file}")
    {:noreply, State.build_graph(state)}
  end

  @impl true
  def handle_call({:get_route, from_city, to_city}, _from, state) do
    {:reply, State.get_route(state, from_city, to_city), state}
  end

  def handle_call(msg, from, state) do
    Logger.warning("Server got unknow call #{inspect(msg)} from #{inspect(from)}")
    {:reply, {:error, :invalid_call}, state}
  end

  @impl true
  def handle_cast(:reload_data, state) do
    {:noreply, state, {:continue, :build_graph}}
  end

  def handle_cast(msg, state) do
    Logger.warning("Server got unknow cast #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Server got unknow info #{inspect(msg)}")
    {:noreply, state}
  end
end
