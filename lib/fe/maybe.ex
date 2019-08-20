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
  Creates an `FE.Maybe` representing the absence of a value.
  """
  @spec nothing() :: t(any)
  def nothing, do: :nothing

  @doc """
  Creates an `FE.Maybe` representing the value passed as an argument.
  """
  @spec just(a) :: t(a) when a: var
  def just(value), do: {:just, value}

  @doc """
  Creates an `FE.Maybe` from any Elixir term.

  It creates a non-value from `nil` and a value from any other term.
  Please note that false, 0, the empty list, etc., are valid values.

  ## Examples
      iex> FE.Maybe.new(nil)
      FE.Maybe.nothing()

      iex> FE.Maybe.new(:x)
      FE.Maybe.just(:x)

      iex> FE.Maybe.new(false)
      FE.Maybe.just(false)
  """
  @spec new(a | nil) :: t(a) when a: var
  def new(term)
  def new(nil), do: nothing()
  def new(value), do: just(value)

  @doc """
  Transforms an `FE.Maybe` value using the provided function.
  Nothing is done if there is no value.

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
  Returns the value stored in a `FE.Maybe` or the provided default if there is no value.

  ## Examples
      iex> FE.Maybe.unwrap_or(FE.Maybe.nothing(), 0)
      0

      iex> FE.Maybe.unwrap_or(FE.Maybe.just(5), 0)
      5
  """
  @spec unwrap_or(t(a), a) :: a when a: var
  def unwrap_or(maybe, default)
  def unwrap_or(:nothing, default), do: default
  def unwrap_or({:just, value}, _), do: value

  @doc """
  Passes the value stored in `FE.Maybe` as input to the first function, or returns the provided default.

  ## Examples
      iex> FE.Maybe.unwrap_with(FE.Maybe.nothing(), fn(x) -> x+1 end, 0)
      0

      iex> FE.Maybe.unwrap_with(FE.Maybe.just(4), fn(x) -> x+1 end, 0)
      5

      iex> FE.Maybe.unwrap_with(FE.Maybe.just("a"), fn(x) -> x <> "bc" end, "xyz")
      "abc"
  """
  @spec unwrap_with(t(a), (a -> b), b) :: b when a: var, b: var
  def unwrap_with(maybe, on_just, default)
  def unwrap_with(:nothing, _, default), do: default
  def unwrap_with({:just, value}, on_just, _), do: on_just.(value)

  @doc """
  Returns the value stored in an `FE.Maybe`. Raises an `FE.Maybe.Error` if a non-value is passed.

  ## Examples
      iex> FE.Maybe.unwrap!(FE.Maybe.just(:value))
      :value

      iex> try do FE.Maybe.unwrap!(FE.Maybe.nothing()) ; rescue e -> e end
      %FE.Maybe.Error{message: "unwrapping Maybe that has no value"}
  """
  @spec unwrap!(t(a)) :: a | no_return() when a: var
  def unwrap!(maybe)
  def unwrap!({:just, value}), do: value
  def unwrap!(:nothing), do: raise(Error, "unwrapping Maybe that has no value")

  @doc """
  Passes the value of `FE.Maybe` to the provided function and returns its return value,
  that should be of the type `FE.Maybe`.

  Useful for chaining together a computation consisting of multiple steps, each of which
  takes a value as an argument and returns a `FE.Maybe`.

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
  Folds over the provided list of elements, where the accumulator and each element
  in the list are passed to the provided function.


  The provided function must returns a new accumulator of the `FE.Maybe` type.
  The provided `FE.Maybe` is the initial accumulator.

  Returns the last `FE.Maybe` returned by the function.

  Stops and returns `nothing()` if at any step the function returns `nothing`.

  ## Examples
      iex> FE.Maybe.fold(FE.Maybe.nothing(), [], &FE.Maybe.just(&1))
      FE.Maybe.nothing()

      iex> FE.Maybe.fold(FE.Maybe.just(5), [], &FE.Maybe.just(&1))
      FE.Maybe.just(5)

      iex> FE.Maybe.fold(FE.Maybe.nothing(), [1, 2], &FE.Maybe.just(&1 + &2))
      FE.Maybe.nothing()

      iex> FE.Maybe.fold(FE.Maybe.just(1), [1, 1], &FE.Maybe.just(&1 + &2))
      FE.Maybe.just(3)

      iex> FE.Maybe.fold(FE.Maybe.just(1), [1, 2, -2, 3], fn
      ...>   elem, _acc when elem < 0 -> FE.Maybe.nothing()
      ...>   elem, acc -> FE.Maybe.just(elem+acc)
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
      iex> FE.Maybe.fold([1,2,3], fn elem, acc -> FE.Maybe.just(elem+acc) end)
      FE.Maybe.just(6)

      iex> FE.Maybe.fold([1], fn elem, acc -> FE.Maybe.just(elem+acc) end)
      FE.Maybe.just(1)

      iex> FE.Maybe.fold([1], fn _, _ -> FE.Maybe.nothing() end)
      FE.Maybe.just(1)

      iex> FE.Maybe.fold([1, 2, 3], &(FE.Maybe.just(&1 + &2)))
      FE.Maybe.just(6)

      iex> FE.Maybe.fold([1, -22, 3], fn
      ...>   elem, _acc when elem < 0 -> FE.Maybe.nothing()
      ...>   elem, acc -> FE.Maybe.just(elem+acc)
      ...> end)
      FE.Maybe.nothing()
  """
  @spec fold([b], (b, a -> t(a))) :: t(a) when a: var, b: var
  def fold(elems, f)
  def fold([], _), do: raise(Enum.EmptyError)
  def fold([head | tail], f), do: fold(just(head), tail, f)

  @doc """
  Transforms an `FE.Maybe` to an `FE.Result`.

  An `FE.Maybe` with a value becomes a successful value of a `FE.Result`.

  A `FE.Maybe` without a value wrapped becomes an erroneous `FE.Result`, where
  the second argument is used as the error's value.


  ## Examples
      iex> FE.Maybe.to_result(FE.Maybe.just(3), "No number found")
      FE.Result.ok(3)

      iex> FE.Maybe.to_result(FE.Maybe.nothing(), "No number found")
      FE.Result.error("No number found")
  """
  @spec to_result(t(a), b) :: Result.t(a, b) when a: var, b: var
  def to_result(maybe, error)
  def to_result({:just, value}, _), do: Result.ok(value)
  def to_result(:nothing, error), do: Result.error(error)

  @doc """
  Transforms an `FE.Maybe` to an `FE.Review`.

  An `FE.Maybe` with a value becomes an accepted `FE.Review` with the same value.

  An `FE.Maybe` without a value wrapped becomes a rejected `FE.Review`, where
  the issues are takens from the second argument to the function.


  ## Examples
      iex> FE.Maybe.to_review(FE.Maybe.just(3), ["No number found"])
      FE.Review.accepted(3)

      iex> FE.Maybe.to_review(FE.Maybe.nothing(), ["No number found"])
      FE.Review.rejected(["No number found"])
  """
  @spec to_review(t(a), [b]) :: Review.t(a, b) when a: var, b: var
  def to_review(maybe, issues)
  def to_review({:just, value}, _), do: Review.accepted(value)
  def to_review(:nothing, issues), do: Review.rejected(issues)
end
