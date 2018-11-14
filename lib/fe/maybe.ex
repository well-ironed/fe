defmodule FE.Maybe do
  @moduledoc """
  `FE.Maybe` is an explicit data type for representing values that might or might not exist.
  """
  @type t(a) :: {:just, a} | :nothing

  @doc """
  Creates a `FE.Maybe` representing a non-value.
  """
  @spec nothing() :: t(any)
  def nothing, do: :nothing

  @doc """
  Creates a `FE.Maybe` representing value passed as an argument.
  """
  @spec just(a) :: t(a) when a: var
  def just(value), do: {:just, value}

  @doc """
  Creates a `FE.Maybe` from any Elixir term.

  It creates a non-value from `nil` and a value from any other term.

  ## Examples
      iex> FE.Maybe.new(nil)
      FE.Maybe.nothing()

      iex> FE.Maybe.new(:x)
      FE.Maybe.just(:x)
  """
  @spec new(a | nil) :: t(a) when a: var
  def new(term)
  def new(nil), do: nothing()
  def new(value), do: just(value)

  @doc """
  Transforms a `FE.Maybe` value using a provided function.

  ## Examples
      iex> FE.Maybe.map(FE.Maybe.nothing(), &String.length/1)
      FE.Maybe.nothing()

      iex> FE.Maybe.map(FE.Maybe.just("foo"), &String.length/1)
      FE.Maybe.just(3)
  """
  @spec map(t(a), (a -> a)) :: t(a) when a: var
  def map(maybe, f)
  def map(:nothing, _), do: nothing()
  def map({:just, value}, f), do: just(f.(value))

  @doc """
  Returns the value stored in a `FE.Maybe` or a provided default if it's a non-value. 

  ## Examples
      iex> FE.Maybe.with_default(FE.Maybe.nothing(), :default)
      :default

      iex> FE.Maybe.with_default(FE.Maybe.just(:value), :default)
      :value
  """
  @spec with_default(t(a), a) :: a when a: var
  def with_default(maybe, default)
  def with_default(:nothing, default), do: default
  def with_default({:just, value}, _), do: value

  @doc """
  Applies value of `FE.Maybe` to a provided function and returns its return value,
  that should be of `FE.Maybe` type.

  Useful for chaining together a computation consisting of multiple steps, each of which
  takes `FE.Maybe` as an argument and returns a `FE.Maybe`.

  ## Examples
      iex> FE.Maybe.and_then(FE.Maybe.nothing(), fn s -> FE.Maybe.just(String.length(s)) end)
      FE.Maybe.nothing()

      iex> FE.Maybe.and_then(FE.Maybe.just("foobar"), fn s -> FE.Maybe.just(String.length(s)) end)
      FE.Maybe.just(6)

      iex> FE.Maybe.and_then(FE.Maybe.just("foobar"), fn _ -> FE.Maybe.nothing() end)
      FE.Maybe.nothing()
  """
  @spec and_then(t(a), (a -> t(a))) :: t(a) when a: var
  def and_then(maybe, f)
  def and_then(:nothing, _), do: nothing()
  def and_then({:just, value}, f), do: f.(value)
end
