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
    # puzzle = Dictionary.get()
    puzzle = "skill"

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
    # case Dictionary.is_entry(word) do
    #   {:ok, _word} ->
    GenServer.call(server, {:put_player_move, word})

    #   {:error, error} ->
    #     {:error, error}
    # end
  end

  @doc """
  Returns if the game is over.

  ## Examples

      iex> Pordle.game_over?(server)
      true

  """
  def game_over?(server) do
    GenServer.call(server, {:game_over})
  end

  @doc """
  Returns the game's status.

  ## Examples

      iex> Pordle.get_status(server)
      :won

  """
  def get_status(server), do: GenServer.call(server, {:get_status})

  @doc """
  Returns a list of chars used by the player during the game.

  ## Examples

      iex> get_chars_used(server)
      [{"a", :hit}, {"f", :nearly}, {"c", :miss}, ...]

  """
  def get_chars_used(server) do
    GenServer.call(server, {:get_chars_used})
  end

  @doc """
  Returns the game board for the given `game`.

  ## Examples

      iex> get_board(server)
      [[{"s", :hit}, {"h", :nearly}, {"f", :miss}, ...], ...]

  """
  def get_board(server) do
    GenServer.call(server, {:get_board})
  end

  @doc """
  Returns the game struct for the given `server`.

  ## Examples

      iex> get_game(server)
      %Game{}

  """
  def get_game(server), do: GenServer.call(server, {:get_game})
end
