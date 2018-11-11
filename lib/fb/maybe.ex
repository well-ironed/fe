defmodule FB.Maybe do
  @moduledoc """
  `FB.Maybe` is an explicit data type for representing values that might or might not exist.
  """
  @type t(a) :: {:just, a} | :nothing

  @doc """
  Creates a `FB.Maybe` representing a non-value.
  """
  @spec nothing() :: t(any)
  def nothing, do: :nothing

  @doc """
  Creates a `FB.Maybe` representing value passed as an argument.
  """
  @spec just(a) :: t(a) when a: var
  def just(value), do: {:just, value}

  @doc """
  Creates a `FB.Maybe` from any Elixir term.

  It creates a non-value from `nil` and a value from any other term.

  ## Examples
      iex> FB.Maybe.new(nil)
      FB.Maybe.nothing()

      iex> FB.Maybe.new(:x)
      FB.Maybe.just(:x)
  """
  @spec new(a | nil) :: t(a) when a: var
  def new(term)
  def new(nil), do: nothing()
  def new(value), do: just(value)

  @doc """
  Transforms a `FB.Maybe` value using a provided function.

  ## Examples
      iex> FB.Maybe.map(FB.Maybe.nothing(), &String.length/1)
      FB.Maybe.nothing()

      iex> FB.Maybe.map(FB.Maybe.just("foo"), &String.length/1)
      FB.Maybe.just(3)
  """
  @spec map(t(a), (a -> a)) :: t(a) when a: var
  def map(maybe, f)
  def map(:nothing, _), do: nothing()
  def map({:just, value}, f), do: just(f.(value))

  @doc """
  Returns the value stored in a `FB.Maybe` or a provided default if it's a non-value. 

  ## Examples
      iex> FB.Maybe.with_default(FB.Maybe.nothing(), :default)
      :default

      iex> FB.Maybe.with_default(FB.Maybe.just(:value), :default)
      :value
  """
  @spec with_default(t(a), a) :: a when a: var
  def with_default(maybe, default)
  def with_default(:nothing, default), do: default
  def with_default({:just, value}, _), do: value

  @doc """
  Applies value of `FB.Maybe` to a provided function and returns its return value,
  that should be of `FB.Maybe` type.

  Useful for chaining together a computation consisting of multiple steps, each of which
  takes `FB.Maybe` as an argument and returns a `FB.Maybe`.

  ## Examples
      iex> FB.Maybe.and_then(FB.Maybe.nothing(), fn s -> FB.Maybe.just(String.length(s)) end)
      FB.Maybe.nothing()

      iex> FB.Maybe.and_then(FB.Maybe.just("foobar"), fn s -> FB.Maybe.just(String.length(s)) end)
      FB.Maybe.just(6)

      iex> FB.Maybe.and_then(FB.Maybe.just("foobar"), fn _ -> FB.Maybe.nothing() end)
      FB.Maybe.nothing()
  """
  @spec and_then(t(a), (a -> t(a))) :: t(a) when a: var
  def and_then(maybe, f)
  def and_then(:nothing, _), do: nothing()
  def and_then({:just, value}, f), do: f.(value)
end
