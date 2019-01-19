defmodule Game.SessionSupervisor do
  use DynamicSupervisor

  @me SessionSupervisor

  def connect() do
    {:ok, pid} = DynamicSupervisor.start_child(@me, Game.Session)
    Game.SessionStore.add(pid)
  end

  def disconnect(session_id) do
    pid = Game.SessionStore.session_id_to_pid(session_id)
    DynamicSupervisor.terminate_child(@me, pid)
    Game.SessionStore.remove(session_id)
  end

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @me)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
