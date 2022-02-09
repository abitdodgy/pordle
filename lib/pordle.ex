defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a word guessing game built by
  Josh Wardle, and was built to provide a Portuguese language version
  of the game.

  This module contains the public API for interacting with game.

  """
  alias Pordle.{GameSupervisor, Game, Dictionary}

  @doc """
  Creates a new Pordle game server with the given options.

  See `Pordle.Game` for available options.

  ## Examples

      iex> {:ok, pid} = Pordle.create_game()
      {:ok, pid}

      iex> {:ok, pid} = Pordle.create_game(opts)
      {:ok, pid}

  """
  def create_game(opts \\ []) do
    opts
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

  @doc """
  Returns whether the game is over for the given `server`.

  ## Examples

      iex> Pordle.game_over?(server)
      true

  """
  def game_over?(server), do: GenServer.call(server, {:game_over})

  @doc """
  Returns the game's result for the given `server`.

  See `Pordle.Game` for possible values.

  ## Examples

      iex> Pordle.get_result(server)
      :won

  """
  def get_result(server), do: GenServer.call(server, {:get_result})

  @doc """
  Returns a list of chars used by the player for the given `server`.

  See `Pordle.Game` for possible values.

  ## Examples

      iex> get_chars_used(server)
      [{"a", :hit}, {"f", :nearly}, {"c", :miss}, ...]

  """
  def get_chars_used(server), do: GenServer.call(server, {:get_chars_used})

  @doc """
  Returns the game board for the given `server`.

  ## Examples

      iex> get_board(server)
      [[{"s", :hit}, {"h", :nearly}, {"f", :miss}, ...]]

  """
  def get_board(server), do: GenServer.call(server, {:get_board})

  @doc """
  Returns the game struct for the given `server`.

  ## Examples

      iex> get_game(server)
      %Game{}

  """
  def get_game(server), do: GenServer.call(server, {:get_game})
end
