defmodule AnalyseFruitsSPTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import AnalyseFruitsSP

  test "data_1" do
    assert start(["./data/data_1.csv"]) == %{
             "apples" => 100,
             "tomatos" => 20,
             "potato" => 17,
             "tangerin" => 289,
             "ananas" => 14
           }
  end

  test "data_2" do
    assert start(["./data/data_2.csv"]) == %{
             "melon" => 332,
             "cucumber" => 12,
             "tangerin" => 23,
             "pear" => 52,
             "apples" => 120,
             "potato" => 77
           }
  end

  test "data_3" do
    assert start(["./data/data_3.csv"]) == %{
             "apples" => 25,
             "tangerin" => 18,
             "pear" => 6
           }
  end

  test "data_1 and 2" do
    assert start(["./data/data_1.csv", "./data/data_2.csv"]) == %{
             "apples" => 220,
             "tomatos" => 20,
             "potato" => 94,
             "tangerin" => 312,
             "ananas" => 14,
             "melon" => 332,
             "cucumber" => 12,
             "pear" => 52
           }
  end

  test "data_2 and 3" do
    assert start(["./data/data_2.csv", "./data/data_3.csv"]) == %{
             "melon" => 332,
             "cucumber" => 12,
             "tangerin" => 41,
             "pear" => 58,
             "apples" => 145,
             "potato" => 77
           }
  end

  test "data_1 and 2 and 3" do
    assert start(["./data/data_1.csv", "./data/data_2.csv", "./data/data_3.csv"]) == %{
             "apples" => 245,
             "tomatos" => 20,
             "potato" => 94,
             "tangerin" => 330,
             "ananas" => 14,
             "melon" => 332,
             "cucumber" => 12,
             "pear" => 58
           }
  end

  test "data_4 invalid file" do
    files = [
      "./data/data_1.csv",
      "./data/data_2.csv",
      "./data/data_3.csv",
      "./data/data_4.csv"
    ]

    msg = "Invalid string format in file ./data/data_4.csv: 1,apples,blablabla"

    assert {:error, ^msg} = start(files)
  end

  test "data_5 not existing file" do
    files = [
      "./data/data_1.csv",
      "./data/data_2.csv",
      "./data/data_3.csv",
      "./data/data_5.csv"
    ]

    msg = "could not stream \"./data/data_5.csv\": no such file or directory"

    assert {:error, ^msg} = start(files)
  end
end
