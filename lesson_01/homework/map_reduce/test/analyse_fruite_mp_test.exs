defmodule AnalyseFruitsMPTest do
  use ExUnit.Case, async: true

  import AnalyseFruitsMP

  setup_all context do
    # don't write crashes to standard output
    Logger.configure(level: :emergency)
    context
  end

  test "data_1" do
    assert start(["./data/data_1.csv"]) ==
             {:ok,
              %{
                "apples" => 100,
                "tomatos" => 20,
                "potato" => 17,
                "tangerin" => 289,
                "ananas" => 14
              }}
  end

  test "data_2" do
    assert start(["./data/data_2.csv"]) ==
             {:ok,
              %{
                "melon" => 332,
                "cucumber" => 12,
                "tangerin" => 23,
                "pear" => 52,
                "apples" => 120,
                "potato" => 77
              }}
  end

  test "data_3" do
    assert start(["./data/data_3.csv"]) ==
             {:ok,
              %{
                "apples" => 25,
                "tangerin" => 18,
                "pear" => 6
              }}
  end

  test "data_1 and 2" do
    assert start(["./data/data_1.csv", "./data/data_2.csv"]) ==
             {:ok,
              %{
                "apples" => 220,
                "tomatos" => 20,
                "potato" => 94,
                "tangerin" => 312,
                "ananas" => 14,
                "melon" => 332,
                "cucumber" => 12,
                "pear" => 52
              }}
  end

  test "data_2 and 3" do
    assert start(["./data/data_2.csv", "./data/data_3.csv"]) ==
             {:ok,
              %{
                "melon" => 332,
                "cucumber" => 12,
                "tangerin" => 41,
                "pear" => 58,
                "apples" => 145,
                "potato" => 77
              }}
  end

  test "data_1 and 2 and 3" do
    assert start(["./data/data_1.csv", "./data/data_2.csv", "./data/data_3.csv"]) ==
             {:ok,
              %{
                "apples" => 245,
                "tomatos" => 20,
                "potato" => 94,
                "tangerin" => 330,
                "ananas" => 14,
                "melon" => 332,
                "cucumber" => 12,
                "pear" => 58
              }}
  end

  test "data_4 invalid file" do
    files = [
      "./data/data_1.csv",
      "./data/data_2.csv",
      "./data/data_3.csv",
      "./data/data_4.csv"
    ]

    error = %FileParser.InvalidStringFormatError{
      file: "./data/data_4.csv",
      line: "1,apples,blablabla"
    }

    assert {:error, {^error, _}} = start(files, 2)
  end

  test "data_5 not existing file" do
    files = [
      "./data/data_1.csv",
      "./data/data_2.csv",
      "./data/data_3.csv",
      "./data/data_5.csv"
    ]

    assert {:error, {%File.Error{reason: :enoent}, _}} = start(files)
  end
end
