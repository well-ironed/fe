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
end
