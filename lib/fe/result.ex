defmodule FE.Result do
  @moduledoc """
  `FE.Result` is a data type for representing output of a computation that either succeed or fail.
  """
  @type t(a, b) :: {:ok, a} | {:error, b}
  @type t(a) :: t(a, any)

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
  def unwrap!({:error, _}), do: raise(Error, "unwrapping Result with an error")

  @doc """
  Applies success value of a `FE.Result` to a provided function and returns its return value,
  that should be of `FE.Result` type.

  Useful for chaining together a computation consisting of multiple steps, each of which
  takes success value wrapped in `FE.Result` as an argument and returns a `FE.Result`.

  ## Examples
      iex> FE.Result.and_then(FE.Result.error("foo"), &FE.Result.ok(String.length(&1)))
      FE.Result.error("foo")

      iex> FE.Result.and_then(FE.Result.ok("bar"), &FE.Result.ok(String.length(&1)))
      FE.Result.ok(3)

      iex> FE.Result.and_then(FE.Result.ok("bar"), fn _ -> FE.Result.error(:baz) end)
      FE.Result.error(:baz)
  """
  @spec and_then(t(a, b), (a -> t(c, b))) :: t(c, b) when a: var, b: var, c: var
  def and_then(result, f)
  def and_then({:error, _} = error, _), do: error
  def and_then({:ok, value}, f), do: f.(value)

  @doc """
  Applies first element from the provided list and the success value of the provided
  `FE.Result` to the provided function, that should return a `FE.Result`.
  Then applies the second element from the list and the value of the
  returned `FE.result` to the function and so on.

  Returns last value returned by the function.

  If at any moment the function returns an error the folding stops and returns the error.

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
end
