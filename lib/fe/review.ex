defmodule FE.Review do
  @type t(a, b) :: {:accepted, a} | {:issues, a, [b]} | {:rejected, [b]}
  @type step(a, b) :: {:ok, a} | {:issue, b} | {:reject, [b]}

  @spec ok(a) :: step(a, any) when a: var
  def ok(value), do: {:ok, value}

  @spec issue(b) :: step(any, b) when b: var
  def issue(issue), do: {:issue, issue}

  @spec reject([b]) :: step(any, b) when b: var
  def reject(issues) when is_list(issues), do: {:reject, issues}

  @spec accepted(a) :: t(a, any) when a: var
  def accepted(value), do: {:accepted, value}

  @spec rejected([b]) :: t(any, b) when b: var
  def rejected(issues) when is_list(issues), do: {:rejected, issues}

  @spec issues(a, b) :: t(a, b) when a: var, b: var
  def issues(value, issues) when is_list(issues), do: {:issues, value, issues}

  @spec map(t(a, b), (a -> c)) :: t(c, b) when a: var, b: var, c: var
  def map(result, f)
  def map({:accepted, value}, f), do: accepted(f.(value))
  def map({:issues, value, issues}, f), do: issues(f.(value), issues)
  def map({:rejected, issues}, _), do: rejected(issues)

  @spec and_then(t(a, b), (a -> step(c, b))) :: t(c, b) when a: var, b: var, c: var
  def and_then(result, f)

  def and_then({:accepted, value}, f) do
    case f.(value) do
      {:ok, value} -> accepted(value)
      {:issue, issue} -> issues(value, [issue])
      {:reject, issues} -> rejected(issues)
    end
  end

  def and_then({:issues, value, issues}, f) do
    case f.(value) do
      {:ok, value} -> issues(value, issues)
      {:issue, issue} -> issues(value, [issue | issues])
      {:reject, issues} -> rejected(issues)
    end
  end

  def and_then({:rejected, value}, _), do: {:rejected, value}

  @spec accept_or_reject(t(a, b)) :: t(a, b) when a: var, b: var
  def accept_or_reject({:accepted, value}), do: accepted(value)
  def accept_or_reject({:rejected, issues}), do: rejected(issues)
  def accept_or_reject({:issues, _, issues}), do: rejected(issues)
end
