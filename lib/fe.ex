defmodule FE do
  @moduledoc """
  Basic functional programming idioms.
  """

  @doc """
  Always return the argument unchanged.
  """
  @spec id(a) :: a when a: var
  def id(a), do: a

  @doc """
  Create a unary function that always returns the same value, regardless
  of what it was called with.
  """
  @spec const(a) :: (any -> a) when a: var
  def const(a), do: fn _ -> a end
  
  @doc """
  Transforms a n-ary function in an unary one that accepts its first
  argument and returns a function expecting the next one, successively
  """
  @spec curry((a, ... -> any())) :: (a -> any()) when a: var
  def curry(fun) do
    {_, arity} = :erlang.fun_info(fun, :arity)
    curry(fun, arity, [])
  end

  defp curry(fun, 0, args) do
    apply(fun, Enum.reverse args)
  end
  defp curry(fun, arity, args) do
    fn arg -> curry(fun, arity - 1, [arg | args]) end
  end
end
