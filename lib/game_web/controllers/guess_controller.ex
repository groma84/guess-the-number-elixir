defmodule GameWeb.GuessController do
  use GameWeb, :controller

  @session_id_key "sessionId"
  @guess_key "guess"

  def guess(conn, _params) do
    session_id = Map.fetch!(conn.query_params, @session_id_key) |> String.to_integer()
    guess = Map.fetch!(conn.query_params, @guess_key) |> String.to_integer()

    json(conn, %{result: Game.Session.guess(session_id, guess)})
  end
end
