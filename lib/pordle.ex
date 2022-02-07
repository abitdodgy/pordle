defmodule Pordle do
  @moduledoc """
  Documentation for `Pordle`.

  """
  alias Pordle.{GameSupervisor, Game, Dictionary}

  @doc """
  Creates a new Pordle game server with the given options.

  ## Examples

      iex> {:ok, pid} = Pordle.create_game()
      {:ok, pid}

      iex> {:ok, pid} = Pordle.create_game([])
      {:ok, pid}

  """
  def create_game(opts \\ []) do
    puzzle = Dictionary.get()

    opts
    |> Keyword.put(:answer, puzzle)
    |> Game.new()
    |> GameSupervisor.start_child()
  end

  @doc """
  Puts the player move onto the board.

  ## Examples

      iex> Pordle.put_player_move(server, word)
      {:ok, pid}

  """
  def put_player_move(server, word) do
    case Dictionary.is_entry(word) do
      {:ok, _word} ->
        GenServer.call(server, {:put_player_move, word})

      {:error, error} ->
        {:error, error}
    end
  end
end
