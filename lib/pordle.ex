defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a game built by Josh Wardle.

  """
  alias Pordle.{GameSupervisor, GameServer}

  defdelegate play_move(name, move), to: GameServer
  defdelegate get_state(name), to: GameServer
  defdelegate exit(name), to: GameServer

  @doc """
  Creates a new supervised game server with the given options.

  Set the number of moves (guesses) a player can make with the `moves_allowed` option.

  ## Examples

      iex> Pordle.create_game(name: "game", puzzle: "crate")
      {:ok, pid}

      iex> Pordle.create_game(name: "game", puzzle: "crate", moves_allowed: 5)
      {:ok, pid}

  ## Options

    - `name` A process identifier that is stored in the Registry.
    - `puzzle` A puzzle to solve.
    - `moves_allowed` The maximum number of guesses the player can make before the game ends. Defaults to `6`.

  """
  def create_game(opts) do
    GameSupervisor.start_child(opts)
  end
end
