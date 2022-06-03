defmodule Polyn.SchemaGenerator do
  @moduledoc false
  def run(args) do
    create_directory(args)
    validate_uniqueness(args)
    validate_name(args)
  end

  defp create_directory(%{dir: dir}) do
    File.mkdir_p!(dir)
  end

  defp validate_uniqueness(%{dir: dir, name: name}) do
    if File.exists?(Path.join(dir, file_name(name))) do
      Mix.raise("Schema can't be created, there is already a schema file with name #{name}.")
    end
  end

  defp validate_name(%{name: name}) do
    case Polyn.Naming.validate_event_name(name) do
      :ok ->
        :ok

      {:error, reason} ->
        Mix.raise("Schema can't be created, #{inspect(reason)}.")
    end
  end

  defp file_name(name) do
    "#{name}.json"
  end
end
