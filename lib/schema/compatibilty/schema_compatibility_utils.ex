defmodule Polyn.SchemaCompatability.Utils do
  @moduledoc false
  def find_values(state, path, key) do
    {find_deepest(path, key, state.old), find_deepest(path, key, state.new)}
  end

  def find_deepest(path, target, json) when is_binary(path) do
    String.split(path, "/")
    |> Enum.map(&path_fragment_to_integer/1)
    |> find_deepest(target, json)
  end

  # Root
  def find_deepest(["" | tail], target, json) do
    find_deepest(tail, target, json)
  end

  # Not found
  def find_deepest([], _target, val) do
    val
  end

  def find_deepest([key | tail], target, json) when is_integer(key) do
    find_deepest(tail, target, Enum.at(json, key))
  end

  def find_deepest([target | tail], target, json) do
    if Enum.member?(tail, target) do
      find_deepest(tail, target, json)
    else
      json[target]
    end
  end

  def find_deepest([key | tail], target, json) do
    find_deepest(tail, target, json[key])
  end

  defp path_fragment_to_integer(part) do
    String.to_integer(part)
  rescue
    _ -> part
  end
end
