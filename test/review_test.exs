defmodule FE.ReviewTest do
  use ExUnit.Case, async: true
  doctest FE.Review

  alias FE.{Review, Result, Maybe}

  test "accepted can be created with a constructor" do
    assert Review.accepted(:baz) == {:accepted, :baz}
  end

  test "rejected can be created with a constructor" do
    assert Review.rejected([123]) == {:rejected, [123]}
  end

  test "issues can be created with a constructor" do
    assert Review.issues(:a, [:b, :c, :d]) == {:issues, :a, [:b, :c, :d]}
  end

  test "mapping over an accepted value applies function to value" do
    assert Review.map(Review.accepted("foo"), &String.length/1) == Review.accepted(3)
  end

  test "mapping over value with issues applies function to value" do
    assert Review.map(Review.issues("foo", [:a, :b, :c]), &String.length/1) ==
             Review.issues(3, [:a, :b, :c])
  end

  test "mapping over rejected returns rejected" do
    assert Review.map(Review.rejected([1, 2, 3]), &String.length/1) == Review.rejected([1, 2, 3])
  end

  test "map_issues over an accepted review returns the same review" do
    assert Review.map_issues(Review.accepted("ack"), &String.length/1) == Review.accepted("ack")
  end

  test "map_issues over issues returns the same value and transformed issues" do
    assert Review.map_issues(Review.issues(:value, ["a", "bb", "ccc"]), &String.length/1) ==
             Review.issues(:value, [1, 2, 3])
  end

  test "map_issues over rejected returns rejected with transformed issues" do
    assert Review.map_issues(Review.rejected([1, 2, 3]), &(&1 * 3)) == Review.rejected([3, 6, 9])
  end

  test "unwrap_or returns default value if rejected is passed" do
    assert Review.unwrap_or(Review.rejected([1]), :default) == :default
  end

  test "unwrap_or returns default value if issues are passed" do
    assert Review.unwrap_or(Review.issues(1, [2, 3]), "default") == "default"
  end

  test "unwrap_or returns wrapped value if accepted is passed" do
    assert Review.unwrap_or(Review.accepted("value"), "default") == "value"
  end

  test "unwrap! returns wrapped value if accepted is passed" do
    assert Review.unwrap!(Review.accepted("value")) == "value"
  end

  test "unwrap! raises an exception with issues in message if rejected is passed" do
    assert_raise Review.Error, "unwrapping rejected Review with issues: [:a]", fn ->
      Review.unwrap!(Review.rejected([:a]))
    end
  end

  test "unwrap! raises an exception with issues in message if issues are passed" do
    assert_raise Review.Error, "unwrapping Review with issues: [2, 3, 4]", fn ->
      Review.unwrap!(Review.issues(1, [2, 3, 4]))
    end
  end

  test "and_then returns accepted if accepted is passed and " <>
         "accepted is returned from function" do
    accepted = Review.accepted(3)

    assert Review.and_then(accepted, fn x -> Review.accepted(x * 3) end) == Review.accepted(9)
  end

  test "and_then returns issues if accepted is passed and " <> "issues are returned from function" do
    accepted = Review.accepted("bar")

    assert Review.and_then(accepted, fn "bar" ->
             Review.issues("baz", ["set too high"])
           end) == {:issues, "baz", ["set too high"]}
  end

  test "and_then returns rejected if accepted is passed and " <>
         "rejected is returned from function" do
    accepted = Review.accepted(10)

    assert Review.and_then(accepted, fn x -> Review.rejected([x + 2]) end) ==
             Review.rejected([12])
  end

  test "and_then returns rejected if rejected is passed" do
    rejected = Review.rejected([123])
    assert Review.and_then(rejected, fn x -> Review.accepted(x + 2) end) == rejected
  end

  test "and_then returns concat of issues if issues are passed and " <>
         "issues are returned from function" do
    issues = Review.issues(1, [1])

    assert Review.and_then(issues, fn x -> Review.issues(x * 2, [x + 1]) end) ==
             Review.issues(2, [1, 2])
  end

  test "and_then returns issues and new value if issues are passed and " <>
         "accepted is returned from function" do
    issues = Review.issues(:foo, [:bar, :baz])

    assert Review.and_then(issues, fn x ->
             Review.accepted(Atom.to_string(x))
           end) == Review.issues("foo", [:bar, :baz])
  end

  test "and_then returns rejected with collected issues " <>
         "if issues is passed and rejected is returned from function" do
    issues = Review.issues(:a, [:b, :c])

    assert Review.and_then(issues, fn _ -> Review.rejected([:x]) end) ==
             Review.rejected([:b, :c, :x])
  end

  test "and_then chain collects issues on the way" do
    result =
      Review.accepted(1)
      |> Review.and_then(&Review.issues(&1, [&1 * 2, &1 * 3]))
      |> Review.and_then(&Review.accepted(&1 + 3))
      |> Review.and_then(&Review.issues(&1 + 1, [&1 * 5, &1 * 4]))

    assert result == Review.issues(5, [2, 3, 20, 16])
  end

  test "and_then chain stops on the first rejected and collects all issues on the way" do
    result =
      Review.accepted(1)
      |> Review.and_then(&Review.issues(&1, [&1 * 2]))
      |> Review.and_then(&Review.rejected([&1 * 3]))
      |> Review.and_then(&Review.issues(&1, [&1 * 4]))

    assert result == Review.rejected([2, 3])
  end

  test "and_then cain returns last if there are no issues on the way" do
    result =
      Review.accepted(1)
      |> Review.and_then(&Review.accepted(&1 + 2))
      |> Review.and_then(&Review.accepted(&1 * 3))
      |> Review.and_then(&Review.accepted(&1 - 4))

    assert result == Review.accepted(5)
  end

  test "fold/3 over an empty list returns whatever is passed as initial review" do
    f = fn _, _ -> Review.accepted(:qux) end
    assert Review.fold(Review.accepted(:foo), [], f) == Review.accepted(:foo)

    assert Review.fold(Review.issues(:bar, [1, 2]), [], f) == Review.issues(:bar, [1, 2])

    assert Review.fold(Review.rejected([:baz]), [], f) == Review.rejected([:baz])
  end

  test "fold/3 over a single value doesn't apply function if rejected is passed" do
    assert Review.fold(Review.rejected([:a]), [5], &Review.accepted(&1 + &2)) ==
             Review.rejected([:a])
  end

  test "fold/3 over a single value applies function if issues are passed" do
    assert Review.fold(Review.issues(1, [:a]), [2], &Review.accepted(&1 + &2)) ==
             Review.issues(3, [:a])

    assert Review.fold(Review.accepted(1), [5], &Review.accepted(&1 - &2)) == Review.accepted(4)
  end

  test "fold/3 over a single value applies function and collects issues" do
    assert Review.fold(Review.issues(1, [:a, :b]), [2], &Review.issues(&1 - &2, [:c, :d])) ==
             Review.issues(1, [:a, :b, :c, :d])
  end

  test "fold/3 over values returns last value returned by function if everything is accepted" do
    assert Review.fold(Review.accepted(1), [2, 3, 4], &Review.accepted(&1 * &2)) ==
             Review.accepted(24)
  end

  test "fold/3 over values returns rejected when the function returns it" do
    assert Review.fold(Review.accepted(1), [2, 3, 4], fn
             _, 6 -> Review.rejected(["it's", "a", "six!"])
             x, y -> Review.accepted(x + y)
           end) == Review.rejected(["it's", "a", "six!"])
  end

  test "fold/3 over values collects issues returned by the function" do
    assert Review.fold(Review.accepted(1), [2, 3, 4, 5], fn
             x, 3 -> Review.issues(x + 3, ["three"])
             x, 10 -> Review.issues(x + 10, ["ten"])
             x, y -> Review.accepted(x + y)
           end) == Review.issues(15, ["three", "ten"])
  end

  test "fold/2 over an empty list raises an EmptyError" do
    assert_raise Enum.EmptyError,
                 fn -> Review.fold([], fn _, _ -> Review.accepted(:foo) end) end
  end

  test "fold/2 over a single value returns this value as an accepted review" do
    assert Review.fold([1], fn _, _ -> Review.rejected([:foo]) end) == Review.accepted(1)
  end

  test "fold/2 over values returns last value returned by function if every step is accepted" do
    assert Review.fold([1, 2, 3, 4, 5], &Review.accepted(&1 + &2)) == Review.accepted(15)
  end

  test "fold/2 over values returns rejected when the function returns it" do
    assert Review.fold([1, 2, 3, 4, 5], fn
             _, 10 -> Review.rejected(["ten", "TEN", "Ten"])
             x, y -> Review.accepted(x + y)
           end) == Review.rejected(["ten", "TEN", "Ten"])
  end

  test "fold/2 over values collects issues returned by function" do
    assert Review.fold([1, 2, 3, 4, 5], fn x, y -> Review.issues(x + y, [y]) end) ==
             Review.issues(15, [1, 3, 6, 10])
  end

  test "fold/2 over values returns collected issues when rejected is returned from function" do
    assert Review.fold([1, 2, 3, 4, 5], fn
             _, 10 -> Review.rejected([10])
             x, y -> Review.issues(x + y, [y])
           end) == Review.rejected([1, 3, 6, 10])
  end

  test "to_result converts accepted value to an ok value" do
    accepted = Review.accepted(:baz)
    assert Review.to_result(accepted) == Result.ok(:baz)
  end

  test "to_result converts rejected to an error with all the issues" do
    rejected = Review.rejected([:a, :b, :c])
    assert Review.to_result(rejected) == Result.error([:a, :b, :c])
  end

  test "to_result converts issues to an error with all the issues" do
    issues = Review.issues(1, [:one, "one", 'one'])
    assert Review.to_result(issues) == Result.error([:one, "one", 'one'])
  end

  test "to_maybe converts accepted value to just value" do
    accepted = Review.accepted(:qux)
    assert Review.to_maybe(accepted) == Maybe.just(:qux)
  end

  test "to_maybe converts rejected to nothing" do
    rejected = Review.rejected(["d", "e", "f"])
    assert Review.to_maybe(rejected) == Maybe.nothing()
  end

  test "to_maybe converts issues to nothing" do
    issues = Review.issues(2, [:two, "two", 'TWO'])
    assert Review.to_maybe(issues) == Maybe.nothing()
  end
end
