defmodule Game.SessionStore do
  use Agent

  @me SessionStore

  def start_link(_) do
    Agent.start_link(fn -> %{next_id: 1} end, name: @me)
  end

  def add(pid) do
    Agent.get_and_update(@me, fn store ->
      {next_id, store} = Map.get_and_update(store, :next_id, fn old -> {old, old + 1} end)
      store = Map.put(store, next_id, pid)
      {next_id, store}
    end)
  end

  def remove(session_id) do
    Agent.update(@me, &Map.delete(&1, session_id))
  end

  def session_id_to_pid(session_id) do
    Agent.get(@me, &Map.get(&1, session_id))
  end
end
