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
  Alias for compose/2
  """
  def f <|> g when is_function(f, 1) and is_function(g, 1) do
    compose(f, g)
  end

  @doc """
  Given two functions of one argument f and g, create a function that
  will apply first g, then f to its argument.
  """
  @spec compose((y -> z), (x -> y)) :: (x -> z) when x: var, y: var, z: var
  def compose(f, g) do
    fn x -> f.(g.(x)) end
  end
end
