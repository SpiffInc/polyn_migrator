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
    errors =
      Enum.reduce(diffs, [], fn diff, acc ->
        check_diff(acc, diff)
      end)
      |> Enum.reject(&(&1 == :ok))

    if Enum.empty?(errors) do
      :ok
    else
      raise Polyn.SchemaException, Enum.join(errors, "\n")
    end
  end

  defp check_diff(errors, diff) do
    required_change?(errors, diff)
  end

  defp required_change?(errors, %{"path" => path} = diff) do
    if String.contains?(path, "required") do
      required_message(errors, diff)
    else
      errors
    end
  end

  defp required_message(errors, %{"op" => "add"} = diff) do
    add_error(
      errors,
      "You added required fields of #{inspect(diff["value"])} at path \"#{diff["path"]}\". " <>
        "Making fields that were previously optional, required is not backwards-compatibile"
    )
  end

  defp add_error(errors, message) do
    Enum.concat(errors, [message])
  end
end
