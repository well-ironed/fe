defmodule ReviewTest do
  use ExUnit.Case, async: true

  alias FE.Review

  test "ok step can be created with a constructor" do
    assert Review.ok(:foo) == {:ok, :foo}
  end

  test "issue step can be created with a constructor" do
    assert Review.issue(:bar) == {:issue, :bar}
  end

  test "reject step can be created with a constructor" do
    assert Review.reject([:baz]) == {:reject, [:baz]}
  end

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

  test "mapping over value wrapped in issue applies function to value" do
    assert Review.map(Review.issues("foo", [:a, :b, :c]), &String.length/1) ==
             Review.issues(3, [:a, :b, :c])
  end

  test "mapping over rejected returns rejected" do
    assert Review.map(Review.rejected([1, 2, 3]), &String.length/1) == Review.rejected([1, 2, 3])
  end

  test "and_then returns accepted if accepted is passed and accepted is returned from function" do
    accepted = Review.accepted(3)
    assert Review.and_then(accepted, fn x -> Review.ok(x * 3) end) == Review.accepted(9)
  end

  test "and_then returns one issue if accepted is passed and an issue is returned from function" do
    accepted = Review.accepted("bar")

    assert Review.and_then(accepted, fn "bar" -> Review.issue("set too high") end) ==
             {:issues, "bar", ["set too high"]}
  end

  test "and_then returns rejected if accepted is passed and rejected is returned from function" do
    accepted = Review.accepted(10)
    assert Review.and_then(accepted, fn x -> Review.reject([x + 2]) end) == Review.rejected([12])
  end

  test "and_then returns rejected if rejected is passed" do
    rejected = Review.rejected([123])
    assert Review.and_then(rejected, fn x -> Review.ok(x + 2) end) == rejected
  end

  test "and_then returns two issues if one issue is passed and an issue is returned from function" do
    issues = Review.issues(1, [1])
    assert Review.and_then(issues, fn x -> Review.issue(x + 1) end) == Review.issues(1, [2, 1])
  end

  test "and_then returns issues and new value if issues are passed and ok is returned from function" do
    issues = Review.issues(:foo, [:bar, :baz])

    assert Review.and_then(issues, fn x -> Review.ok(Atom.to_string(x)) end) ==
             Review.issues("foo", [:bar, :baz])
  end

  test "and_then returns rejected if issues is passed and rejected is returned from function" do
    issues = Review.issues(:a, [:b, :c])
    assert Review.and_then(issues, fn _ -> Review.reject([:x]) end) == Review.rejected([:x])
  end

  test "accept_or_reject doesn't change accepted value" do
    accepted = Review.accepted(:baz)
    assert Review.accept_or_reject(accepted) == accepted
  end

  test "accept_or_reject doesn't change rejected issues" do
    rejected = Review.rejected(["foo", "bar"])
    assert Review.accept_or_reject(rejected) == rejected
  end

  test "accept_or_reject transform it to rejected if issues are passed" do
    issues = Review.issues(:a, [:b, :c, :d])
    assert Review.accept_or_reject(issues) == Review.rejected([:b, :c, :d])
  end

  test "and_then chain collects issues on the way" do
    result =
      Review.accepted(1)
      |> Review.and_then(&Review.issue(&1 * 2))
      |> Review.and_then(&Review.ok(&1 + 3))
      |> Review.and_then(&Review.issue(&1 * 5))

    assert result == Review.issues(4, [20, 2])
  end

  test "and_then chain stops on the first reject" do
    result =
      Review.accepted(1)
      |> Review.and_then(&Review.issue(&1 * 2))
      |> Review.accept_or_reject()
      |> Review.and_then(&Review.issue(&1 * 5))

    assert result == Review.rejected([2])
  end

  test "and_then cain returns last if there are no issues on the way" do
    result =
      Review.accepted(1)
      |> Review.and_then(&Review.ok(&1 + 2))
      |> Review.and_then(&Review.ok(&1 * 3))
      |> Review.and_then(&Review.ok(&1 - 4))

    assert result == Review.accepted(5)
  end
end
