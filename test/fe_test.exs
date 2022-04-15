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

  test "f <|> g yields a function that is a composition of f and g" do
    import FE, only: [<|>: 2]
    f = fn x -> {:f, x} end
    g = fn x -> {:g, x} end

    comp = f <|> g

    assert comp.(1) == {:f, {:g, 1}}
  end

  test "f <|> g does not accept non-function arguments" do
    import FE, only: [<|>: 2]
    f = fn x -> {:f, x} end
    g = [:a, :list]

    assert_raise FunctionClauseError, fn ->
      _ = f <|> g
    end

    assert_raise FunctionClauseError, fn ->
      _ = g <|> f
    end
  end

  test "f <|> g only accepts functions of one argument" do
    import FE, only: [<|>: 2]
    f2 = fn x, y -> {:f, {x, y}} end
    f1 = fn x -> {:f, x} end
    f0 = fn -> {:f} end

    assert_raise FunctionClauseError, fn ->
      _ = f2 <|> f1
    end

    assert_raise FunctionClauseError, fn ->
      _ = f0 <|> f1
    end
  end
end
