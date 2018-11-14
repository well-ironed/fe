defmodule FE.MaybeTest do
  use ExUnit.Case, async: true
  doctest FE.Maybe

  alias FE.Maybe

  test "nothing can be created with a constructor" do
    assert Maybe.nothing() == :nothing
  end

  test "just value can be created with a constructor" do
    assert Maybe.just(5) == {:just, 5}
  end

  test "nothing is created from nil" do
    assert Maybe.new(nil) == Maybe.nothing()
  end

  test "just is created from any other value" do
    assert Maybe.new(3) == Maybe.just(3)
    assert Maybe.new("foo") == Maybe.just("foo")
  end

  test "map doesn't apply function to nothing" do
    assert Maybe.map(Maybe.nothing(), &(&1 + 1)) == Maybe.nothing()
  end

  test "map applies function to just value" do
    assert Maybe.map(Maybe.just(5), &(&1 * 2)) == Maybe.just(10)
    assert Maybe.map(Maybe.just("bar"), &String.length/1) == Maybe.just(3)
  end

  test "unwrap_or returns default value if nothing is passed" do
    assert Maybe.unwrap_or(Maybe.nothing(), :default) == :default
  end

  test "unwrap_or returns just value if just is passed" do
    assert Maybe.unwrap_or(Maybe.just(5), nil) == 5
    assert Maybe.unwrap_or(Maybe.just("five"), :ok) == "five"
  end

  test "and_then returns nothing if nothing is passed" do
    assert Maybe.and_then(Maybe.nothing(), fn _ -> Maybe.nothing() end) == Maybe.nothing()
  end

  test "and_then applies function if just is passed" do
    assert Maybe.and_then(Maybe.just(5), fn x -> Maybe.just(x + 10) end) == Maybe.just(15)
    assert Maybe.and_then(Maybe.just("5"), fn _ -> Maybe.nothing() end) == Maybe.nothing()
  end
end
