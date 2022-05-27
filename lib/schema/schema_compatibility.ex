defmodule Polyn.SchemaCompatability do
  @moduledoc false

  @doc """
  Check that a new schema is backwards-compatibile with a new schema
  """
  def check!(nil, _new), do: :ok

  def check!(old, new) do
    JSONDiff.diff(old, new)
    |> IO.inspect(label: "DIFFS")
    |> check_differences()
  end

  defp check_differences([]), do: :ok

  defp check_differences(diffs) do
    Enum.map(diffs, &check_diff/1)
  end

  defp check_diff(diff) do
    required_change?([], diff)
  end

  defp required_change?(errors, %{"path" => path} = _diff) do
    if String.contains?(path, "required") do
    else
      errors
    end
  end
end
