defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a game built by Josh Wardle.

  """
  alias Pordle.{GameSupervisor, GameServer}

  defdelegate play_move(name), to: GameServer
  defdelegate insert_char(name, char), to: GameServer
  defdelegate delete_char(name), to: GameServer
  defdelegate get_state(name), to: GameServer
  defdelegate exit(name), to: GameServer

  @doc """
  Creates a new supervised game server with the given options.

  If a game `name` or `puzzle` are not given, Pordle will automatically generate ones.
  A puzzle is generated using a `Pordle.Dictionary` implementation.

  Set the number of moves (guesses) a player can make with the `moves_allowed` option.

  ## Examples

      iex> Pordle.create_game(name: "game", puzzle: "crate")
      {:ok, pid}

      iex> Pordle.create_game(name: "game", puzzle: "crate", moves_allowed: 5)
      {:ok, pid}

  ## Options

    - `name` A process identifier that is stored in the Registry. Automatically generated unless provided.
    - `puzzle` A puzzle to solve.
    - `moves_allowed` The maximum number of guesses the player can make before the game ends. Defaults to `6`.

  """
  def create_game(opts \\ []) do
    {name, opts} =
      Keyword.get_and_update(opts, :name, fn current_value ->
        current_value =
          if is_nil(current_value) do
            puid()
          end

        {current_value, current_value}
      end)

    {:ok, pid} = GameSupervisor.start_child(opts)
    {:ok, pid, name}
  end

  defp puid(size \\ 16) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def config(key) do
    Application.fetch_env!(:pordle, key)
  end
end
