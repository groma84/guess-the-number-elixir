defmodule Game.Session do
  use GenServer
  alias Game.GameState

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    {:ok, %GameState{number: Enum.random(1..100)}}
  end

  def guess(session_id, guess) do
    pid = Game.SessionStore.session_id_to_pid(session_id)
    GenServer.call(pid, {:guess, guess})
  end

  def handle_call({:guess, guess}, _from, %GameState{number: number, guesses: guesses}) do
    result =
      cond do
        Enum.member?(guesses, number) -> :already_guessed
        guess == number -> :correct
        guess < number -> :wrong_higher
        guess > number -> :wrong_lower
      end

    {:reply, result, %GameState{number: number, guesses: [guess | guesses]}}
  end
end
