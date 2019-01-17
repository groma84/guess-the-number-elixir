defmodule Game.Session do
  use GenServer
  alias Game.GameState

  # API
  @spec guess(Game.Types.session_id(), Game.Types.guess()) ::
          :fatal_error | :correct | :wrong_higher | :wrong_lower | :already_guessed
  def guess(session_id, guess) do
    send_guess(guess, Game.SessionStore.id_to_pid(session_id))
  end

  defp send_guess(_guess, :error) do
    :fatal_error
  end

  defp send_guess(guess, {:ok, pid}) do
    GenServer.call(pid, {:guess, guess})
  end

  # GenServer
  def init(:no_args) do
    {:ok, %GameState{number: Enum.random(1..100)}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def handle_call({:guess, guess}, _from, state) do
    result =
      case Enum.member?(state.guesses, guess) do
        true ->
          :already_guessed

        false ->
          case guess === state.number do
            true ->
              :correct

            false ->
              if guess < state.number do
                :wrong_higher
              else
                :wrong_lower
              end
          end
      end

    {:reply, result, %GameState{state | guesses: [guess | state.guesses]}}
  end

  defp check_guess(guess, number) do
    case guess === number do
      true ->
        :correct

      false ->
        if guess < number do
          :wrong_higher
        else
          :wrong_lower
        end
    end
  end
end
