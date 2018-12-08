defmodule FE.Review do
  @moduledoc """
  `FE.Review` is a data type similar to `FE.Result`, made for representing
  output of a computation that either succeed (`accepted`) or fail (`rejected`),
  but that might continue despite of issues encountered (`issues`).

  One could say that the type is a specific implementation of a writer monad,
  that collects issues encountered during some computation.

  For instance, it might be used for validation of a user input, when we don't
  want to stop the process of validation when we encounter the first mistake,
  but rather we would like to collect all the user's mistakes before returning
  feedback to her.
  """

  @type t(a, b) :: {:accepted, a} | {:issues, a, [b]} | {:rejected, [b]}

  alias FE.Result

  defmodule Error do
    defexception [:message]
  end

  @doc """
  Creates a `FE.Review` representing a successful output of a computation.
  """
  @spec accepted(a) :: t(a, any) when a: var
  def accepted(value), do: {:accepted, value}

  @doc """
  Creates a `FE.Review` representing an errornous output of a computation with
  a list of issues encountered during the computation.
  """
  @spec rejected([b]) :: t(any, b) when b: var
  def rejected(issues) when is_list(issues), do: {:rejected, issues}

  @doc """
  Creates a `FE.Review` representing a problematic output of a computation
  that there were some issues with.
  """
  @spec issues(a, b) :: t(a, b) when a: var, b: var
  def issues(value, issues) when is_list(issues), do: {:issues, value, issues}

  @doc """
  Transforms a successful or a problematic value in a `FE.Review` using
  a provided function.

  ## Examples
      iex> FE.Review.map(FE.Review.rejected(["foo"]), &String.length/1)
      FE.Review.rejected(["foo"])

      iex> FE.Review.map(FE.Review.issues("foo", ["b", "ar"]), &String.length/1)
      FE.Review.issues(3, ["b", "ar"])

      iex> FE.Review.map(FE.Review.accepted("baz"), &String.length/1)
      FE.Review.accepted(3)
  """
  @spec map(t(a, b), (a -> c)) :: t(c, b) when a: var, b: var, c: var
  def map(review, f)
  def map({:accepted, value}, f), do: accepted(f.(value))
  def map({:issues, value, issues}, f), do: issues(f.(value), issues)
  def map({:rejected, issues}, _), do: rejected(issues)

  @doc """
  Transform issues stored in a `FE.Review` using a provided function.

  ## Examples
      iex> FE.Review.map_issues(FE.Review.accepted("ack!"), &String.length/1)
      FE.Review.accepted("ack!")

      iex> FE.Review.map_issues(FE.Review.issues("a", ["bb", "ccc"]), &String.length/1)
      FE.Review.issues("a", [2, 3])

      iex> FE.Review.map_issues(FE.Review.rejected(["dddd", "eeeee"]), &String.length/1)
      FE.Review.rejected([4, 5])
  """
  @spec map_issues(t(a, b), (b -> c)) :: t(a, c) when a: var, b: var, c: var
  def map_issues(review, f)
  def map_issues({:accepted, value}, _), do: accepted(value)

  def map_issues({:issues, value, issues}, f) do
    issues(value, Enum.map(issues, f))
  end

  def map_issues({:rejected, issues}, f) do
    rejected(Enum.map(issues, f))
  end

  @doc """
  Returns the accepted value stored in a `FE.Review` or a provided default if
  either rejected or value with issues is passed

  ## Examples
      iex> FE.Review.unwrap_or(FE.Review.rejected(["no", "way"]), :default)
      :default

      iex> FE.Review.unwrap_or(FE.Review.issues(1, ["no", "way"]), :default)
      :default

      iex> FE.Review.unwrap_or(FE.Review.accepted(123), :default)
      123
  """
  @spec unwrap_or(t(a, any), a) :: a when a: var
  def unwrap_or(review, default)
  def unwrap_or({:rejected, _}, default), do: default
  def unwrap_or({:issues, _, _}, default), do: default
  def unwrap_or({:accepted, value}, _), do: value

  @doc """
  Returns the accepted value stored in a `FE.Review`, raises an `FE.Review.Error`
  if either rejected or value with issues is passed

  ## Examples
      iex> FE.Review.unwrap!(FE.Review.accepted("foo"))
      "foo"
  """
  @spec unwrap!(t(a, any)) :: a when a: var
  def unwrap!(review)
  def unwrap!({:accepted, value}), do: value
  def unwrap!({:rejected, _}), do: raise(Error, "unwrapping rejected Review")

  def unwrap!({:issues, _, _}),
    do: raise(Error, "unwrapping Review with issues")

  @doc """
  Transforms `FE.Review` into a `FE.Result`.

  Any accepted value of a `FE.Review` becomes a successful value of a `FE.Result`.

  If there are any issues either in a rejected `FE.Review` or coupled with a value,
  all the issues become a errornous output of the output `FE.Result`.

  ## Examples
      iex> FE.Review.to_result(FE.Review.issues(1, [2, 3]))
      FE.Result.error([2, 3])

      iex> FE.Review.to_result(FE.Review.accepted(4))
      FE.Result.ok(4)

      iex> FE.Review.to_result(FE.Review.rejected([5, 6, 7]))
      FE.Result.error([5, 6, 7])
  """

  @spec to_result(t(a, b)) :: Result.t(a, [b]) when a: var, b: var
  def to_result(review)
  def to_result({:accepted, value}), do: Result.ok(value)
  def to_result({:rejected, issues}), do: Result.error(issues)
  def to_result({:issues, _, issues}), do: Result.error(issues)

  @doc """
  Applies accepted value of a `FE.Review` to a provided function.
  Returns its return value, that should be of `FE.Review` type.

  Applies value with issues of a `FE.Review` to a provided function.
  If accepted value is returned, then the value is replaced, but the issues
  remain the same.
  If new value with issues is returned, then the value is replaced and the issues
  are appended to the list of current issues.
  If rejected is returned, then the issues are appended to the list of current issues,
  if issues were passed.

  Useful for chaining together a computation consisting of multiple steps,
  each of which takes either a success value or value with issues wrapped in
  `FE.Review` as an argument and returns a `FE.Review`.

  ## Examples
      iex> FE.Review.and_then(
      ...>  FE.Review.rejected(["foo"]),
      ...>  &FE.Review.accepted(String.length(&1)))
      FE.Review.rejected(["foo"])

      iex> FE.Review.and_then(
      ...>  FE.Review.issues("foo", ["bar", "baz"]),
      ...>  &FE.Review.accepted(String.length(&1)))
      FE.Review.issues(3, ["bar", "baz"])

      iex> FE.Review.and_then(
      ...>  FE.Review.issues("foo", ["bar", "baz"]),
      ...>  &FE.Review.issues(String.length(&1), ["qux"]))
      FE.Review.issues(3, ["bar", "baz", "qux"])

      iex> FE.Review.and_then(FE.Review.accepted(1), &FE.Review.issues(&1, [:one]))
      FE.Review.issues(1, [:one])
  """
  @spec and_then(t(a, b), (a -> t(c, b))) :: t(c, b) when a: var, b: var, c: var
  def and_then(review, f)

  def and_then({:accepted, value}, f) do
    case f.(value) do
      {:accepted, value} -> accepted(value)
      {:issues, value, issues} -> issues(value, issues)
      {:rejected, issues} -> rejected(issues)
    end
  end

  def and_then({:issues, value, issues}, f) do
    case f.(value) do
      {:accepted, value} -> issues(value, issues)
      {:issues, value, new_issues} -> issues(value, issues ++ new_issues)
      {:rejected, new_issues} -> rejected(issues ++ new_issues)
    end
  end

  def and_then({:rejected, value}, _), do: {:rejected, value}

  @doc """
  Equivalent to calling chain of `and_then`s where every step executes
  the provided function, with a single element of the list applied as its first
  argument.

  ## Examples
      iex> FE.Review.fold(FE.Review.rejected([:error]), [],
      ...>  &FE.Review.accepted(&1 + &2))
      FE.Review.rejected([:error])

      iex> FE.Review.fold(FE.Review.accepted(5), [1, 2, 3],
      ...>   &FE.Review.accepted(&1 * &2))
      FE.Review.accepted(30)

      iex> FE.Review.fold(FE.Review.accepted(5), [1, 2, 3],
      ...>   &FE.Review.issues(&1 * &2, [&1]))
      FE.Review.issues(30, [1, 2, 3])

      iex> FE.Review.fold(FE.Review.issues(5, [:five]), [1, 2, 3],
      ...>   &FE.Review.accepted(&1 * &2))
      FE.Review.issues(30, [:five])

      iex> FE.Review.fold(FE.Review.accepted(5), [1, 2, 3], fn
      ...>   x, 10 -> FE.Review.issues(x * 10, ["it's a ten!"])
      ...>   x, y -> FE.Review.accepted(x * y)
      ...> end)
      FE.Review.issues(30, ["it's a ten!"])

      iex> FE.Review.fold(FE.Review.accepted(5), [1, 2, 3], fn
      ...>   _, 10 -> FE.Review.rejected(["it's a ten!"])
      ...>   x, y -> FE.Review.accepted(x * y)
      ...> end)
      FE.Review.rejected(["it's a ten!"])
  """
  @spec fold(t(a, b), [c], (c, a -> t(a, b))) :: t(a, b) when a: var, b: var, c: var
  def fold(review, elems, f) do
    Enum.reduce_while(elems, review, fn elem, acc ->
      case and_then(acc, fn value -> f.(elem, value) end) do
        {:accepted, _} = accepted -> {:cont, accepted}
        {:issues, _, _} = issues -> {:cont, issues}
        {:rejected, _} = rejected -> {:halt, rejected}
      end
    end)
  end

  @doc """
  Works like `fold/3`, except that the first element is converted to an accepted
  `FE.Review` value and passed as an initial second argument to the provided function.

  ## Examples
      iex> FE.Review.fold([1], fn _, _ -> FE.Review.rejected([:foo]) end)
      FE.Review.accepted(1)

      iex> FE.Review.fold([1, 2, 3], &FE.Review.accepted(&1 + &2))
      FE.Review.accepted(6)

      iex> FE.Review.fold([1, 2, 3], &FE.Review.issues(&1 + &2, [&2]))
      FE.Review.issues(6, [1, 3])

      iex> FE.Review.fold([1, 2, 3, 4], fn
      ...>   _, 6 -> FE.Review.rejected(["six"])
      ...>   x, y -> FE.Review.issues(x + y, [y])
      ...> end)
      FE.Review.rejected([1, 3, "six"])

      iex> FE.Review.fold([1, 2, 3, 4], fn
      ...>   x, 6 -> FE.Review.issues(x + 6, ["six"])
      ...>   x, y -> FE.Review.accepted(x + y)
      ...> end)
      FE.Review.issues(10, ["six"])
  """
  @spec fold([c], (c, a -> t(a, b))) :: t(a, b) when a: var, b: var, c: var
  def fold([], _), do: raise(Enum.EmptyError)
  def fold([head | tail], f), do: fold(accepted(head), tail, f)
end
