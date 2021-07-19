defmodule FE.MaybeTest do
  use ExUnit.Case, async: true
  doctest FE.Maybe

  alias FE.{Maybe, Result, Review}

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

  test "unwrap_with applies the first function to just value" do
    assert Maybe.unwrap_with(Maybe.just(5), &(&1 * 2), :whatever) == 10
  end

  test "unwrap_with uses function if function provided for nothing" do
    assert Maybe.unwrap_with(Maybe.nothing(), &(&1 * 2), fn -> :whatever end) == :whatever
  end

  test "unwrap_with uses default value for nothing" do
    assert Maybe.unwrap_with(Maybe.nothing(), &(&1 * 2), :whatever) == :whatever
  end

  test "unwrap_or returns default value if nothing is passed" do
    assert Maybe.unwrap_or(Maybe.nothing(), :default) == :default
  end

  test "unwrap_or returns just value if just is passed" do
    assert Maybe.unwrap_or(Maybe.just(5), nil) == 5
    assert Maybe.unwrap_or(Maybe.just("five"), :ok) == "five"
  end

  test "unwrap! returns just value is just is passed" do
    assert Maybe.unwrap!(Maybe.just(3)) == 3
    assert Maybe.unwrap!(Maybe.just("three")) == "three"
  end

  test "unwrap! raises an exception if nothing is passed" do
    assert_raise FE.Maybe.Error, "unwrapping Maybe that has no value", fn ->
      Maybe.unwrap!(Maybe.nothing())
    end
  end

  test "and_then returns nothing if nothing is passed" do
    assert Maybe.and_then(Maybe.nothing(), fn _ -> Maybe.nothing() end) == Maybe.nothing()
  end

  test "and_then applies function if just is passed" do
    assert Maybe.and_then(Maybe.just(5), fn x -> Maybe.just(x + 10) end) == Maybe.just(15)

    assert Maybe.and_then(Maybe.just("5"), fn _ -> Maybe.nothing() end) == Maybe.nothing()
  end

  test "and_then chain stops on first nothing" do
    result =
      Maybe.just(1)
      |> Maybe.and_then(&Maybe.just(&1 + 2))
      |> Maybe.and_then(fn _ -> Maybe.nothing() end)
      |> Maybe.and_then(&Maybe.just(&1 - 4))

    assert result == Maybe.nothing()
  end

  test "and_then chain returns last if there is no nothing on the way" do
    result =
      Maybe.just(1)
      |> Maybe.and_then(&Maybe.just(&1 + 2))
      |> Maybe.and_then(&Maybe.just(&1 * 3))
      |> Maybe.and_then(&Maybe.just(&1 - 4))

    assert result == Maybe.just(5)
  end

  test "fold/3 over an empty list returns passed maybe" do
    assert Maybe.fold(Maybe.nothing(), [], &Maybe.just(&1 + &2)) == Maybe.nothing()

    assert Maybe.fold(Maybe.just(5), [], &Maybe.just(&1 + &2)) == Maybe.just(5)
  end

  test "fold/3 over a single value applies function to it if the just value passed" do
    assert Maybe.fold(Maybe.just(10), [5], &Maybe.just(&1 + &2)) == Maybe.just(15)

    assert Maybe.fold(Maybe.just(20), [3], fn _, _ -> Maybe.nothing() end) == Maybe.nothing()
  end

  test "fold/3 over a single value doesn't apply function if nothing is passed" do
    assert Maybe.fold(Maybe.nothing(), [5], &Maybe.just(&1 + &2)) == Maybe.nothing()
  end

  test "fold/3 over values returns last value returned by function if it returns only justs" do
    assert Maybe.fold(Maybe.just(1), [2, 3, 4], &Maybe.just(&1 * &2)) == Maybe.just(24)
  end

  test "fold/3 over values returns nothing when the function returns it" do
    assert Maybe.fold(Maybe.just(1), [2, 3, 4], fn
             _, 6 -> Maybe.nothing()
             x, y -> Maybe.just(x + y)
           end) == Maybe.nothing()
  end

  test "fold/2 over an empty list raises an EmptyError" do
    assert_raise Enum.EmptyError, fn -> Maybe.fold([], &Maybe.just(&1 + &2)) end
  end

  test "fold/2 over a single value returns this value as just value" do
    assert Maybe.fold([1], fn _, _ -> Maybe.nothing() end) == Maybe.just(1)
  end

  test "fold/2 over values returns last value returned by function if it returns only justs" do
    assert Maybe.fold([5, 6, 7], &Maybe.just(&1 * &2)) == Maybe.just(210)
  end

  test "fold/2 over values returns nothing when the function returns it" do
    assert Maybe.fold([5, 6, 7], fn
             _, 11 -> Maybe.nothing()
             x, y -> Maybe.just(x + y)
           end) == Maybe.nothing()
  end

  test "justs/1 does nothing on empty list" do
    assert Maybe.justs([]) == []
  end

  test "justs/1 preserves ordering" do
    assert Maybe.justs([Maybe.just(1), Maybe.just(2)]) == [1, 2]
  end

  test "justs/1 doesn't return nothings" do
    assert Maybe.justs([Maybe.nothing(), Maybe.nothing()]) == []
  end

  test "justs/1 filters out only justs" do
    assert Maybe.justs([Maybe.nothing(), Maybe.just(2)]) == [2]
  end

  test "to_result converts just value to ok with the same value" do
    just = Maybe.just(123)
    assert Maybe.to_result(just, "error") == Result.ok(123)
  end

  test "to_result converts nothing to error with passed erroreneous value" do
    assert Maybe.to_result(Maybe.nothing(), "it's an error") == Result.error("it's an error")
  end

  test "to_review converts just value to accepted review with the same value" do
    just = Maybe.just(456)
    assert Maybe.to_review(just, ["issue"]) == Review.accepted(456)
  end

  test "to_review converts nothing to rejected review with passed issues" do
    issues = ["issue 1", "issue 2", "issue 3"]
    assert Maybe.to_review(Maybe.nothing(), issues) == Review.rejected(issues)
  end
end
