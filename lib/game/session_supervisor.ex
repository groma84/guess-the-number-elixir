defmodule Game.SessionSupervisor do
  use DynamicSupervisor

  @me SessionSupervisor

  # API
  @spec connect() :: Game.SessionId.session_id()
  def connect() do
    {:ok, pid} = DynamicSupervisor.start_child(@me, Game.Session)
    Game.SessionStore.add(pid)
  end

  @spec disconnect(Game.SessionId.session_id()) :: :ok
  def disconnect(session_id) do
    terminate(session_id, Game.SessionStore.id_to_pid(session_id))
  end

  defp terminate(session_id, {:ok, pid}) do
    DynamicSupervisor.terminate_child(@me, pid)

    Game.SessionStore.remove(session_id)
  end

  defp terminate(_session_id, :error) do
    # NOOP
  end

  # Supervisor
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @me)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
