defmodule PathFinderTest do
  use ExUnit.Case, async: true

  alias PathFinder

  @test_data_file "test/fixtures/test_cities.csv"

  setup_all do
    setup_test_data()
    {:ok, _pid} = PathFinder.start_link(@test_data_file)
    on_exit(fn -> cleanup_test_data() end)

    :ok
  end

  describe "get_city_list/0" do
    test "returns all cities from data file" do
      cities = ["Санкт-Петербург", "Москва", "Казань", "Екатеринбург"]

      assert PathFinder.get_city_list() == Enum.sort(cities)
    end
  end

  describe "get_route/2" do
    test "returns a route and distance between existing cities" do
      assert {:ok, {route1, 1540}} = PathFinder.get_route("Санкт-Петербург", "Казань")
      assert {:ok, {route2, 1540}} = PathFinder.get_route("Казань", "Санкт-Петербург")
      assert route1 == ["Санкт-Петербург", "Москва", "Казань"]
      assert route2 == Enum.reverse(route1)
    end

    test "with same source and destination returns a valid route" do
      assert {:ok, {["Москва"], 0}} = PathFinder.get_route("Москва", "Москва")
    end

    test "with non-existent cities returns error" do
      assert {:error, :no_route} = PathFinder.get_route("Москва", "ГородПризрак")
    end
  end

  describe "add_route/3" do
    test "adds a new connection between cities" do
      old_route = {["Санкт-Петербург", "Москва", "Казань"], 1540}

      assert {:ok, ^old_route} = PathFinder.get_route("Санкт-Петербург", "Казань")

      new_route = {["Санкт-Петербург", "Казань"], 1500}
      PathFinder.add_route("Санкт-Петербург", "Казань", 1500)
      assert {:ok, ^new_route} = PathFinder.get_route("Санкт-Петербург", "Казань")

      PathFinder.reload_data()
      assert {:ok, ^old_route} = PathFinder.get_route("Санкт-Петербург", "Казань")
    end
  end

  # Helper functions

  defp setup_test_data() do
    test_data = """
    CityFrom,CityTo,Distance
    Санкт-Петербург,Москва,700
    Москва,Казань,840
    Казань,Екатеринбург,950
    """

    @test_data_file |> Path.dirname() |> File.mkdir_p!()
    File.write!(@test_data_file, test_data)
  end

  defp cleanup_test_data(), do: File.rm(@test_data_file)
end
