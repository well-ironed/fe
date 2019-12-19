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
end
