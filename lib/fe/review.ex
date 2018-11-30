defmodule FE.Review do
  @type t(a, b) :: {:accepted, a} | {:issues, a, [b]} | {:rejected, [b]}

  defmodule Error do
    defexception [:message]
  end

  @spec accepted(a) :: t(a, any) when a: var
  def accepted(value), do: {:accepted, value}

  @spec rejected([b]) :: t(any, b) when b: var
  def rejected(issues) when is_list(issues), do: {:rejected, issues}

  @spec issues(a, b) :: t(a, b) when a: var, b: var
  def issues(value, issues) when is_list(issues), do: {:issues, value, issues}

  @spec map(t(a, b), (a -> c)) :: t(c, b) when a: var, b: var, c: var
  def map(review, f)
  def map({:accepted, value}, f), do: accepted(f.(value))
  def map({:issues, value, issues}, f), do: issues(f.(value), issues)
  def map({:rejected, issues}, _), do: rejected(issues)

  @spec map_issues(t(a, b), (b -> c)) :: t(a, c) when a: var, b: var, c: var
  def map_issues(review, f)
  def map_issues({:accepted, value}, _), do: accepted(value)

  def map_issues({:issues, value, issues}, f) do
    issues(value, Enum.map(issues, f))
  end

  def map_issues({:rejected, issues}, f) do
    rejected(Enum.map(issues, f))
  end

  @spec unwrap_or(t(a, any), a) :: a when a: var
  def unwrap_or(review, default)
  def unwrap_or({:rejected, _}, default), do: default
  def unwrap_or({:issues, _, _}, default), do: default
  def unwrap_or({:accepted, value}, _), do: value

  @spec unwrap!(t(a, any)) :: a when a: var
  def unwrap!(review)
  def unwrap!({:accepted, value}), do: value
  def unwrap!({:rejected, _}), do: raise(Error, "unwrapping rejected Review")

  def unwrap!({:issues, _, _}),
    do: raise(Error, "unwrapping Review with issues")

  @spec accepted_or_rejected(t(a, b)) :: t(a, b) when a: var, b: var
  def accepted_or_rejected({:accepted, value}), do: accepted(value)
  def accepted_or_rejected({:rejected, issues}), do: rejected(issues)
  def accepted_or_rejected({:issues, _, issues}), do: rejected(issues)

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
      {:rejected, issues} -> rejected(issues)
    end
  end

  def and_then({:rejected, value}, _), do: {:rejected, value}

  @spec fold(t(a, b), [c], (c, a -> t(a, b))) :: t(a, b)
        when a: var, b: var, c: var
  def fold(review, elems, f) do
    Enum.reduce_while(elems, review, fn elem, acc ->
      case and_then(acc, fn value -> f.(elem, value) end) do
        {:accepted, _} = accepted -> {:cont, accepted}
        {:issues, _, _} = issues -> {:cont, issues}
        {:rejected, _} = rejected -> {:halt, rejected}
      end
    end)
  end
end
