defmodule FE.Maybe do
  @moduledoc """
  `FE.Maybe` is an explicit data type for representing values that might or might not exist.
  """

  alias FE.{Result, Review}

  @type t(a) :: {:just, a} | :nothing

  defmodule Error do
    defexception [:message]
  end

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
      iex> FE.Maybe.unwrap_or(FE.Maybe.nothing(), :default)
      :default

      iex> FE.Maybe.unwrap_or(FE.Maybe.just(:value), :default)
      :value
  """
  @spec unwrap_or(t(a), a) :: a when a: var
  def unwrap_or(maybe, default)
  def unwrap_or(:nothing, default), do: default
  def unwrap_or({:just, value}, _), do: value

  @doc """
  Provides the value stored in `FE.Maybe` to the first function, or runs the second function.

  ## Examples
      iex> FE.Maybe.unwrap_with(FE.Maybe.nothing(), fn(x) -> x+1 end, :foo)
      :foo

      iex> FE.Maybe.unwrap_with(FE.Maybe.just("a"), fn(x) -> x <> "bc" end, "xyz")
      "abc"
  """
  @spec unwrap_with(t(a), (a -> b), b) :: b when a: var, b: var
  def unwrap_with(maybe, on_just, default)
  def unwrap_with(:nothing, _, default), do: default
  def unwrap_with({:just, value}, on_just, _), do: on_just.(value)

  @doc """
  Returns the value stored in a `FE.Maybe`, raises a `FE.Maybe.Error` if a non-value is passed.

  ## Examples
      iex> FE.Maybe.unwrap!(FE.Maybe.just(:value))
      :value
  """
  @spec unwrap!(t(a)) :: a | no_return() when a: var
  def unwrap!(maybe)
  def unwrap!({:just, value}), do: value
  def unwrap!(:nothing), do: raise(Error, "unwrapping Maybe that has no value")

  @doc """
  Applies value of `FE.Maybe` to a provided function and returns its return value,
  that should be of `FE.Maybe` type.

  Useful for chaining together a computation consisting of multiple steps, each of which
  takes value wrapped in `FE.Maybe` as an argument and returns a `FE.Maybe`.

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

  @doc """
  Folds over provided list of elements applying it and current accumulator
  to the provided function.

  The provided function returns a new accumulator, that should be a `FE.Maybe`.
  The provided `FE.Maybe` is the initial accumulator.

  Returns last value returned by the function.

  Stops and returns nothing if at any moment the function returns nothing.

  ## Examples
      iex> FE.Maybe.fold(FE.Maybe.nothing(), [], &FE.Maybe.just(&1))
      FE.Maybe.nothing()

      iex> FE.Maybe.fold(FE.Maybe.just(5), [], &FE.Maybe.just(&1))
      FE.Maybe.just(5)

      iex> FE.Maybe.fold(FE.Maybe.nothing(), [1, 2], &FE.Maybe.just(&1 + &2))
      FE.Maybe.nothing()

      iex> FE.Maybe.fold(FE.Maybe.just(5), [6, 7], &FE.Maybe.just(&1 + &2))
      FE.Maybe.just(18)

      iex> FE.Maybe.fold(FE.Maybe.just(5), [6, 7, 8], fn
      ...>   _, 18 -> FE.Maybe.nothing()
      ...>   x, y -> FE.Maybe.just(x+y)
      ...> end)
      FE.Maybe.nothing()
  """
  @spec fold(t(a), [b], (b, a -> t(a))) :: t(a) when a: var, b: var
  def fold(maybe, elems, f) do
    Enum.reduce_while(elems, maybe, fn elem, acc ->
      case and_then(acc, fn value -> f.(elem, value) end) do
        {:just, _} = just -> {:cont, just}
        :nothing -> {:halt, :nothing}
      end
    end)
  end

  @doc """
  Works like `fold/3`, except that the first element of the provided list is removed
  from it, wrapped in a `FE.Maybe` and treated as the initial accumulator.

  Then, fold is executed over the remainder of the provided list.

  ## Examples
      iex> FE.Maybe.fold([1], fn _, _ -> FE.Maybe.nothing() end)
      FE.Maybe.just(1)

      iex> FE.Maybe.fold([1, 2, 3], &(FE.Maybe.just(&1 + &2)))
      FE.Maybe.just(6)

      iex> FE.Maybe.fold([1, 2, 3], fn
      ...>   _, 3 -> FE.Maybe.nothing()
      ...>   x, y -> FE.Maybe.just(x+y)
      ...> end)
      FE.Maybe.nothing()
  """
  @spec fold([b], (b, a -> t(a))) :: t(a) when a: var, b: var
  def fold(elems, f)
  def fold([], _), do: raise(Enum.EmptyError)
  def fold([head | tail], f), do: fold(just(head), tail, f)

  @doc """
  Transforms `FE.Maybe` to a `FE.Result`.

  A `FE.Maybe` with a value wrapped becomes a successful value of a `FE.Result`.

  A `FE.Maybe` without a value wrapped becomes an errornous `FE.Result` with the
  output passed to the function.

  ## Examples
      iex> FE.Maybe.to_result(FE.Maybe.just(3), "error")
      FE.Result.ok(3)

      iex> FE.Maybe.to_result(FE.Maybe.nothing(), "error")
      FE.Result.error("error")
  """
  @spec to_result(t(a), b) :: Result.t(a, b) when a: var, b: var
  def to_result(maybe, error)
  def to_result({:just, value}, _), do: Result.ok(value)
  def to_result(:nothing, error), do: Result.error(error)

  @doc """
  Transforms `FE.Maybe` to a `FE.Review`.

  A `FE.Maybe` with a value wrapped becomes an accepted `FE.Review` with the same value.

  A `FE.Maybe` without a value wrapped becomes a rejected `FE.Review` with the
  issues the same as passed to the function.

  ## Examples
      iex> FE.Maybe.to_review(FE.Maybe.just(3), ["error"])
      FE.Review.accepted(3)

      iex> FE.Maybe.to_review(FE.Maybe.nothing(), ["error"])
      FE.Review.rejected(["error"])
  """
  @spec to_review(t(a), [b]) :: Review.t(a, b) when a: var, b: var
  def to_review(maybe, issues)
  def to_review({:just, value}, _), do: Review.accepted(value)
  def to_review(:nothing, issues), do: Review.rejected(issues)
end
