defmodule Polyn.Migration.Runner do
  # A way to update the migration state without exposing it to
  # developers creating migration files. This will allow Migration
  # functions to update the state without developers needing to be
  # aware of it.
  @moduledoc false
  use Agent

  def start_link(state) do
    Agent.start_link(fn -> state end)
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  @doc "Add a new command to execute to the state"
  def add_command(pid, command) do
    running_migration_id = get_running_migration_id(pid)

    Agent.update(pid, fn state ->
      commands = Enum.concat(state.commands, [{running_migration_id, command}])
      Map.put(state, :commands, commands)
    end)
  end

  # @doc "Add a new migration event to the application migrations state"
  # def add_application_migration(pid, event) do
  #   Agent.update(pid, fn state ->
  #     migrations = Enum.concat(state.application_migrations, [event])
  #     Map.put(state, :application_migrations, migrations)
  #   end)
  # end

  @doc "Update the state to know the id of the migration running"
  def update_running_migration_id(pid, id) do
    Agent.update(pid, fn state ->
      Map.put(state, :running_migration_id, id)
    end)
  end

  # @doc "Update the state to know the number of the command running in the migration"
  # def update_running_migration_command_num(pid, num) do
  #   Agent.update(pid, fn state ->
  #     Map.put(state, :running_migration_command_num, num)
  #   end)
  # end

  def get_running_migration_id(pid) do
    get_state(pid).running_migration_id
  end

  # def get_running_migration_command_num(pid) do
  #   get_state(pid).running_migration_command_num
  # end

  def get_state(pid) do
    Agent.get(pid, fn state -> state end)
  end
end
