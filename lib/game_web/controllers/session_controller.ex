defmodule GameWeb.SessionController do
  use GameWeb, :controller

  def connect(conn, _params) do
    json(conn, %{sessionId: Game.SessionSupervisor.connect()})
  end

  def disconnect(conn, _params) do
    Map.fetch!(conn.query_params, "sessionId")
    |> String.to_integer()
    |> Game.SessionSupervisor.disconnect()

    json(conn, %{done: :ok})
  end
end
