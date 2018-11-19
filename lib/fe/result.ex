defmodule FE.Result do
  @moduledoc """
  `FE.Result` is a data type for representing output of a computation that either succeed or fail.
  """
  @type t(a, b) :: {:ok, a} | {:error, b}
  @type t(a) :: t(a, any)

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
end
