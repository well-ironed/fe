defmodule FETest do
  use ExUnit.Case, async: true

  test "FE.id/1 always returns its argument" do
    some_binary = :crypto.strong_rand_bytes(100)
    a_number = System.unique_integer()
    a_tuple = :erlang.now()

    assert FE.id(some_binary) == some_binary
    assert FE.id(a_number) == a_number
    assert FE.id(a_tuple) == a_tuple
  end

  test "FE.const(x) creates a function that always returns x" do
    some_binary = :crypto.strong_rand_bytes(100)
    a_number = System.unique_integer()
    a_tuple = :erlang.now()

    assert FE.const(some_binary).(a_number) == some_binary
    assert FE.const(a_number).(a_tuple) == a_number
    assert FE.const(a_tuple).(some_binary) == a_tuple
  end

  describe "curry/1" do
    test "function with arity bigger than 0 is curried" do
      fun = fn x -> x end
      result = FE.curry(fun).(1)
      assert result == 1

      fun = fn x, y -> x + y end

      add5 = FE.curry(fun).(5)
      assert add5.(3) == 8

      result = FE.curry(fun).(1).(2)
      assert result == 3

      fun = fn x, y, z -> x + y + z end
      result = FE.curry(fun).(1).(2).(3)
      assert result == 6
    end

    test "function with arity equal 0 raises error" do
      fun = fn -> :ok end
      assert_raise(ArgumentError, fn -> FE.curry(fun) end)
    end
  end
end
