defmodule Play do
  @spec init_sessions(pos_integer()) :: [non_neg_integer()]
  def init_sessions(count) do
    Range.new(1, count)
    |> Enum.map(fn _ ->
      Game.SessionSupervisor.connect()
    end)
  end

  @spec init_sessions([pos_integer()]) :: any()
  def solve_all(session_ids) do
    stream = Task.async_stream(session_ids, &solve_one_session(&1, 42, :start))
    Stream.run(stream)
  end

  defp solve_one_session(session_id, last_number, :correct) do
    Game.SessionSupervisor.disconnect(session_id)

    IO.puts("""
    Processes: #{Process.list() |> Enum.count()} - Solved session_id #{session_id} with guess #{
      last_number
    }
    """)
  end

  defp solve_one_session(session_id, _last_number, :start) do
    guess = 50

    new_result = Game.Session.guess(session_id, guess)

    solve_one_session(session_id, guess, new_result)
  end

  defp solve_one_session(session_id, last_number, previous_result) do
    guess =
      case previous_result do
        :wrong_higher -> last_number + 1
        :wrong_lower -> last_number - 1
      end

    new_result = Game.Session.guess(session_id, guess)

    solve_one_session(session_id, guess, new_result)
  end
end
