defmodule FE.Result do
  @moduledoc """
  `FE.Result` is a data type for representing output of a computation that either succeeded or failed.
  """
  @type t(a, b) :: {:ok, a} | {:error, b}
  @type t(a) :: t(a, any)

  alias FE.{Maybe, Review}

  defmodule Error do
    defexception [:message]
  end

  @doc """
  Creates a `FE.Result` representing a successful output of a computation.
  """
  @spec ok(a) :: t(a) when a: var
  def ok(value), do: {:ok, value}

  @doc """
  Creates a `FE.Result` representing an errorneous output of a computation.
  """
  @spec error(a) :: t(any, a) when a: var
  def error(value), do: {:error, value}

  @doc """
  Transforms a success value in a `FE.Result` using a provided function.

  ## Examples
      iex> FE.Result.map(FE.Result.error("foo"), &String.length/1)
      FE.Result.error("foo")

      iex> FE.Result.map(FE.Result.ok("foo"), &String.length/1)
      FE.Result.ok(3)
  """
  @spec map(t(a, b), (a -> c)) :: t(c, b) when a: var, b: var, c: var
  def map(result, f)
  def map({:error, _} = error, _), do: error
  def map({:ok, value}, f), do: {:ok, f.(value)}

  @doc """
  Transforms an errorneous value in a `FE.Result` using a provided function.

  ## Examples
      iex> FE.Result.map_error(FE.Result.ok("foo"), &String.length/1)
      FE.Result.ok("foo")

      iex> FE.Result.map_error(FE.Result.error("foo"), &String.length/1)
      FE.Result.error(3)
  """
  @spec map_error(t(a, b), (b -> c)) :: t(a, c) when a: var, b: var, c: var
  def map_error(result, f)
  def map_error({:ok, _} = ok, _), do: ok
  def map_error({:error, value}, f), do: {:error, f.(value)}

  @doc """
  Returns the success value stored in a `FE.Result` or a provided default value if an error is passed.

  ## Examples
      iex> FE.Result.unwrap_or(FE.Result.error("foo"), "default")
      "default"

      iex> FE.Result.unwrap_or(FE.Result.ok("bar"), "default")
      "bar"
  """
  @spec unwrap_or(t(a), a) :: a when a: var
  def unwrap_or(result, default)
  def unwrap_or({:error, _}, default), do: default
  def unwrap_or({:ok, value}, _), do: value

  @doc """
  Returns the success value stored in a `FE.Result`, raises an `FE.Result.Error` if an error is passed.
  """
  @spec unwrap!(t(a)) :: a | no_return() when a: var
  def unwrap!(result)
  def unwrap!({:ok, value}), do: value

  def unwrap!({:error, error}) do
    raise(Error, "unwrapping Result with an error: #{inspect(error)}")
  end

  @doc """
  Runs the first function on a success value, or the second function on
  error value, returning the results.

  ## Examples

      iex> FE.Result.ok(1) |> FE.Result.unwrap_with(&inspect/1, &("error: "<> inspect(&1)))
      "1"

      iex> FE.Result.error("db down") |> FE.Result.unwrap_with(&inspect/1, &("error: "<> &1))
      "error: db down"

  """
  @spec unwrap_with(t(a, b), (a -> c), (b -> d)) :: c | d when a: var, b: var, c: var, d: var
  def unwrap_with(result, on_ok, on_error)
  def unwrap_with({:ok, value}, f, _) when is_function(f, 1), do: f.(value)
  def unwrap_with({:error, error}, _, f) when is_function(f, 1), do: f.(error)

  @doc """
  Applies success value of a `FE.Result` to a provided function and returns its return value,
  that should be of `FE.Result` type.

  Useful for chaining together a computation consisting of multiple steps, each of which
  takes success value wrapped in `FE.Result` as an argument and returns a `FE.Result`.

  ## Examples
      iex> FE.Result.error("foo") |> FE.Result.and_then(&FE.Result.ok(String.length(&1)))
      FE.Result.error("foo")

      iex> FE.Result.ok("bar") |> FE.Result.and_then(&FE.Result.ok(String.length(&1)))
      FE.Result.ok(3)

      iex> FE.Result.ok("bar") |> FE.Result.and_then(fn _ -> FE.Result.error(:baz) end)
      FE.Result.error(:baz)
  """
  @spec and_then(t(a, b), (a -> t(c, b))) :: t(c, b) when a: var, b: var, c: var
  def and_then(result, f)
  def and_then({:error, _} = error, _), do: error
  def and_then({:ok, value}, f), do: f.(value)

  @doc """
  Folds over provided list of elements applying it and current accumulator
  to the provided function.

  The provided function returns a new accumulator, that should be a `FE.Result`.
  The provided `FE.Result` is the initial accumulator.

  Returns last value returned by the function.

  Stops and returns error if at any moment the function returns error.

  ## Examples
      iex> FE.Result.fold(FE.Result.error(:error), [], &FE.Result.ok(&1 + &2))
      FE.Result.error(:error)

      iex> FE.Result.fold(FE.Result.ok(5), [], &FE.Result.ok(&1 + &2))
      FE.Result.ok(5)

      iex> FE.Result.fold(FE.Result.error(:foo), [1, 2], &FE.Result.ok(&1 + &2))
      FE.Result.error(:foo)

      iex> FE.Result.fold(FE.Result.ok(5), [1, 2, 3], &FE.Result.ok(&1 * &2))
      FE.Result.ok(30)

      iex> FE.Result.fold(FE.Result.ok(5), [1, 2, 3], fn
      ...> _, 10 -> FE.Result.error("it's a ten!")
      ...> x, y  -> FE.Result.ok(x * y)
      ...> end)
      FE.Result.error("it's a ten!")
  """
  @spec fold(t(a, b), [c], (c, a -> t(a, b))) :: t(a, b) when a: var, b: var, c: var
  def fold(result, elems, f) do
    Enum.reduce_while(elems, result, fn elem, acc ->
      case and_then(acc, fn value -> f.(elem, value) end) do
        {:ok, _} = ok -> {:cont, ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Works like `fold/3`, except that the first element of the provided list is removed
  from it, converted to a success `FE.Result` and treated as the initial accumulator.

  Then, fold is executed over the remainder of the provided list.

  ## Examples
      iex> FE.Result.fold([1], fn _, _ -> FE.Result.error(:one) end)
      FE.Result.ok(1)

      iex> FE.Result.fold([1, 2, 3], &(FE.Result.ok(&1 + &2)))
      FE.Result.ok(6)

      iex> FE.Result.fold([1, 2, 3], fn
      ...>   _, 3 -> FE.Result.error(:three)
      ...>   x, y -> FE.Result.ok(x + y)
      ...> end)
      FE.Result.error(:three)
  """
  @spec fold([c], (c, a -> t(a, b))) :: t(a, b) when a: var, b: var, c: var
  def fold(elems, f)
  def fold([], _), do: raise(Enum.EmptyError)
  def fold([head | tail], f), do: fold(ok(head), tail, f)

  @doc """
  Returns the `FE.Result.ok` values from a list of `FE.Result`s.

  ## Examples
      iex> FE.Result.oks([FE.Result.ok(:good), FE.Result.error(:bad), FE.Result.ok(:better)])
      [:good, :better]
  """

  @spec oks([t(a, any)]) :: [a] when a: var
  def oks(e) do
    Enum.reduce(e, [], fn
      {:ok, val}, acc -> [val | acc]
      {:error, _}, acc -> acc
    end)
    |> Enum.reverse()
  end

  @doc """
  If a list of `FE.Result`s is all `FE.Result.ok`s, returns a `FE.Result.ok`
  where the value is a list of the unwrapped values.

  Otherwise, returns `FE.Result.error` with the first erroneous value.

  ## Examples
      iex> FE.Result.all_ok([FE.Result.ok(:a), FE.Result.ok(:b), FE.Result.ok(:c)])
      FE.Result.ok([:a, :b, :c])
      iex> FE.Result.all_ok([FE.Result.ok(:a), FE.Result.error("BAD APPLE"), FE.Result.ok(:c)])
      FE.Result.error("BAD APPLE")
  """

  @spec all_ok([t(a, any)]) :: t([a], any) when a: var
  def all_ok(list), do: all_ok0(list, [])

  defp all_ok0([], res) when is_list(res), do: Enum.reverse(res) |> ok()
  defp all_ok0([{:ok, v} | tail], res), do: all_ok0(tail, [v | res])
  defp all_ok0([{:error, e} | _], _), do: {:error, e}

  @doc """
  Transforms `FE.Result` to a `FE.Maybe`.

  A `FE.Result` with successful value becomes a `FE.Maybe` with the same value.

  An errornous `FE.Result` becomes a `FE.Maybe` without a value.

  ## Examples
      iex> FE.Result.to_maybe(FE.Result.ok(13))
      FE.Maybe.just(13)

      iex> FE.Result.to_maybe(FE.Result.error("something went wrong"))
      FE.Maybe.nothing()
  """
  @spec to_maybe(t(a, any)) :: Maybe.t(a) when a: var
  def to_maybe(result)
  def to_maybe({:ok, value}), do: Maybe.just(value)
  def to_maybe({:error, _}), do: Maybe.nothing()

  @doc """
  Transforms `FE.Result` to a `FE.Review`.

  A `FE.Result` with successful value becomes an accepted `FE.Review` with
  the same value.

  An errornous `FE.Result` with error output being a list becomes a rejected
  `FE.Review` with issues being exactly this list.

  An errornous `FE.Result` with error output being other term becomes a rejected
  `FE.Review` with one issue, being this term.

  ## Examples
      iex> FE.Result.to_review(FE.Result.ok(23))
      FE.Review.accepted(23)

      iex> FE.Result.to_review(FE.Result.error(["wrong", "bad", "very bad"]))
      FE.Review.rejected(["wrong", "bad", "very bad"])

      iex> FE.Result.to_review(FE.Result.error("error"))
      FE.Review.rejected(["error"])
  """
  @spec to_review(t(a, b) | t(a, [b])) :: Review.t(a, b) when a: var, b: var
  def to_review(result)
  def to_review({:ok, value}), do: Review.accepted(value)
  def to_review({:error, values}) when is_list(values), do: Review.rejected(values)
  def to_review({:error, value}), do: Review.rejected([value])
end
