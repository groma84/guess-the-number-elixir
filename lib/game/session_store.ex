defmodule Game.SessionStore do
  use Agent

  @me SessionStore

  def start_link(_opts) do
    Agent.start_link(fn -> %{next_id: 1} end, name: @me)
  end

  @spec add(pid()) :: Game.Types.session_id()
  def add(pid) do
    Agent.get_and_update(@me, fn store ->
      {next_id, store} =
        Map.get_and_update(store, :next_id, fn old_id -> {old_id, old_id + 1} end)

      store = Map.put(store, next_id, pid)

      {next_id, store}
    end)
  end

  @spec remove(Game.Types.session_id()) :: :ok
  def remove(id) do
    Agent.update(@me, &Map.delete(&1, id))
  end

  @spec id_to_pid(Game.Types.session_id()) :: {:ok, pid()} | :error
  def id_to_pid(session_id) do
    Agent.get(@me, &Map.fetch(&1, session_id))
  end
end
