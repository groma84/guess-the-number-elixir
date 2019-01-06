defmodule GameWeb.SessionController do
  use GameWeb, :controller

  @session_id_key "sessionId"

  def connect(conn, _params) do
    json(conn, %{session_id: Game.SessionSupervisor.connect()})
  end

  def disconnect(conn, _params) do
    Map.fetch!(conn.query_params, @session_id_key)
    |> Game.SessionSupervisor.disconnect()

    json(conn, %{done: :ok})
  end
end
