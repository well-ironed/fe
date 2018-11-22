defmodule FE.ResultTest do
  use ExUnit.Case, async: true
  doctest FE.Result

  alias FE.Result

  test "ok can be created with a constructor" do
    assert Result.ok(:foo) == {:ok, :foo}
  end

  test "error can be created with a constructor" do
    assert Result.error("bar") == {:error, "bar"}
  end

  test "mapping over an error returns the same error" do
    assert Result.map(Result.error(:foo), fn _ -> :bar end) == Result.error(:foo)
  end

  test "mapping over an ok value applies function to value" do
    assert Result.map(Result.ok(2), &(&1 * 5)) == Result.ok(10)
  end

  test "unwrap_or returns default value if an error is passed" do
    assert Result.unwrap_or(Result.error(:foo), :default) == :default
    assert Result.unwrap_or(Result.error("bar"), nil) == nil
  end

  test "unwrap_or returns wrapped value if an ok is passed" do
    assert Result.unwrap_or(Result.ok(:bar), :default) == :bar
    assert Result.unwrap_or(Result.ok(3), :x) == 3
  end

  test "unwrap! returns wrapped value if an ok is passed" do
    assert Result.unwrap!(Result.ok(:foo)) == :foo
  end

  test "unwrap! raises an exception if an error is passed" do
    assert_raise FE.Result.Error, "unwrapping Result with an error", fn ->
      Result.unwrap!(Result.error(:bar))
    end
  end

  test "and_then returns error if an error is passed" do
    assert Result.and_then(Result.error(5), fn x -> Result.ok(x * 2) end) == Result.error(5)
  end

  test "and_then applies function to the ok value that's passed" do
    assert Result.and_then(Result.ok(5), fn x -> Result.ok(x * 2) end) == Result.ok(10)
  end

  test "and_then chain stops on first error" do
    result =
      Result.ok(1)
      |> Result.and_then(&Result.ok(&1 + 2))
      |> Result.and_then(&Result.error(&1 * 3))
      |> Result.and_then(&Result.ok(&1 - 4))

    assert result == Result.error(9)
  end

  test "and_then chain returns last if there is no error on the way" do
    result =
      Result.ok(1)
      |> Result.and_then(&Result.ok(&1 + 2))
      |> Result.and_then(&Result.ok(&1 * 3))
      |> Result.and_then(&Result.ok(&1 - 4))

    assert result == Result.ok(5)
  end

  test "fold over an empty list returns passed result" do
    assert Result.fold(Result.ok(:foo), []) == Result.ok(:foo)
    assert Result.fold(Result.error(:bar), []) == Result.error(:bar)
  end

  test "fold over a single function applies it to the ok value passed" do
    assert Result.fold(Result.ok(10), [&Result.ok(&1 + 5)]) == Result.ok(15)
    assert Result.fold(Result.ok(20), [fn _ -> Result.error(:bar) end]) == Result.error(:bar)
  end

  test "fold over a single function is not applied if error is passed" do
    assert Result.fold(Result.error(:foo), [&Result.ok(&1 + 5)]) == Result.error(:foo)
  end

  test "fold over functions returns last if there is no error on the way" do
    assert Result.fold(
             Result.ok(1),
             [&Result.ok(&1 + 1), &Result.ok(&1 * 5), &Result.ok(&1 - 3)]
           ) == Result.ok(7)
  end

  test "fold over functions stops on first error" do
    assert Result.fold(
             Result.ok(1),
             [
               &Result.ok(&1 + 1),
               &Result.ok(&1 * 5),
               fn _ -> Result.error(:foo) end,
               &Result.ok(&1 - 3)
             ]
           ) == Result.error(:foo)
  end
end
