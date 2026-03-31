defmodule AnalyseFruitsMP do
  @moduledoc """
  MapReduce solution
  """

  @spec test(integer()) :: {:ok, %{String.t() => integer()}} | {:error, term()}
  def test(processes_per_level \\ 2) do
    files = [
      "./data/data_1.csv",
      "./data/data_2.csv",
      "./data/data_3.csv"
    ]

    start(files, processes_per_level)
  end

  @spec start([String.t()], integer()) :: {:ok, %{String.t() => integer()}} | {:error, term()}
  def start(files, processes_per_level \\ 4) do
    files
    |> TreeBuilder.build(processes_per_level)
    |> AnalyseFruitsMP.Coordinator.start_process()

    Process.flag(:trap_exit, true)

    receive do
      {:result, _from, result} -> {:ok, result}
      {:EXIT, _from, reason} when reason != :normal -> {:error, reason}
    after
      1000 -> IO.puts("MapReduce #{inspect(self())} got not messages")
    end
  end

  defmodule Coordinator do
    @moduledoc """
    Starts processes according to tree built by TreeBuilder and waits for results
    """

    alias AnalyseFruitsMP.{Reducer, Mapper}

    @type process() :: TreeBuilder.mapper() | TreeBuilder.reducer()

    @spec start_process(process()) :: pid()
    def start_process({:reducer, _id, children}) do
      spawn_link(Reducer, :run, [self(), children])
    end

    def start_process({:mapper, _id, file}) do
      spawn_link(Mapper, :run, [self(), file])
    end

    @spec start_processes([process()]) :: [pid()]
    def start_processes(nodes) do
      Enum.map(nodes, &start_process/1)
    end
  end

  defmodule Reducer do
    @moduledoc """
    Reducer process, waits for results from mappers and sums them up
    """

    defmodule State do
      @moduledoc """
      State of reducer process
      """

      defstruct [
        :parent,
        :children_count,
        :children,
        result: %{}
      ]

      @type t :: %__MODULE__{
              parent: pid(),
              children_count: non_neg_integer(),
              children: MapSet.t(pid()),
              result: map()
            }

      @spec new(pid(), [pid()]) :: t()
      def new(parent, children) do
        children = MapSet.new(children)
        %__MODULE__{parent: parent, children: children, children_count: MapSet.size(children)}
      end

      @spec handle_message(t(), {:result, pid(), map()}) :: t()
      def handle_message(state, {:result, mapper, result}) do
        if MapSet.member?(state.children, mapper) do
          %{
            state
            | children: MapSet.delete(state.children, mapper),
              children_count: state.children_count - 1,
              result: Map.merge(state.result, result, fn _k, v1, v2 -> v1 + v2 end)
          }
        else
          state
        end
      end
    end

    @spec run(pid(), [TreeBuilder.mapper() | TreeBuilder.reducer()]) :: no_return()
    def run(parent, nodes) do
      loop(State.new(parent, AnalyseFruitsMP.Coordinator.start_processes(nodes)))
    end

    def loop(%State{parent: parent, children_count: 0, result: result}) do
      send(parent, {:result, self(), result})
    end

    def loop(state) do
      receive do
        {:result, mapper, result} ->
          state
          |> State.handle_message({:result, mapper, result})
          |> loop()
      after
        1000 -> IO.puts("Reducer #{inspect(self())} got not messages")
      end
    end
  end

  defmodule Mapper do
    @moduledoc """
    Mapper process, reads file and sends result to parent reducer
    """

    @spec run(pid(), String.t()) :: no_return()
    def run(parent, file) do
      send(parent, {:result, self(), FileParser.parse!(file)})
    end
  end
end
