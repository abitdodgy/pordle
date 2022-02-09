defmodule Pordle.Game do
  @moduledoc """
  This module contains logic to create and interact with a Pordle game.

  """
  alias Pordle.Game

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          player: Map.t(),
          puzzle: nonempty_charlist(),
          puzzle_size: non_neg_integer() | 5,
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won,
          board: list()
        }

  defstruct name: nil,
            board: nil,
            player: nil,
            puzzle: nil,
            result: nil,
            puzzle_size: 5,
            moves_allowed: 6,
            moves_made: 0

  @doc """
  Initializes a new game struct.

  Unless provided, Pordle generates a puzzle with the default puzzle size. The puzzle size can be customised
  with the `puzzle_size` option.

  When a custom puzzle is provided, the `puzzle_size` option is ignored since its value will be derived
  from the given puzzle.

  The number of guesses a player can make can be configured with the `moves_allowed` option.

  ## Examples

      iex> Game.new()
      %Game{name: "OpMIz...", puzzle_size: 5, moves_allowed: 6}

      iex> Game.new(puzzle_size: 6)
      %Game{name: "OpMIz...", puzzle_size: 6}

  ## Options

      - `puzzle` The puzzle to solve. If absent, the game generates a puzzle with the default `puzzle_size`.
      - `puzzle_size` The size of the puzzle. This option is ignored if a custom puzzle is provided. Defaults to `5`.
      - `moves_allowed` The number of guesses the player is allowed to make during the game. Defaults to `6`.
      - `moves_made` The number of guesses the player has made. Defaults to `0`.
      - `result` The result of the game. Can be one of `:active`, `:won`, or `:lost`. Defaults to `active`.
      - `board` The game board. If absent, the game generates a board using the `puzzle_size` and `moves_allowed`.
      - `player` The player.
      - `name` Acts as a game id for the registry. If absent, one is generated automatically.

  """
  def new(opts \\ []) do
    opts =
      opts
      |> put_name()
      |> put_puzzle()
      |> put_player()

    __MODULE__
    |> struct!(opts)
    |> put_board()
  end

  @doc """
  Returns a list of chars used by the player.

  ## Examples

      iex> get_chars_used(game)
      [{"a", :hit}, {"s", :nearly}, ...]

  """
  def get_chars_used(%Game{board: board}) do
    board
    |> List.flatten()
    |> Enum.reject(fn {char, _type} -> is_nil(char) end)
    |> Enum.uniq_by(fn {char, _type} -> char end)
  end

  @doc """
  Returns the result of the given `game`.

  ## Examples

      iex> get_result(game)
      {:ok, :won}

  """
  def get_result(%Game{result: result}), do: {:ok, result}

  @doc """
  Returns the game board.

  ## Examples

      iex> get_board(game)
      [{"a", :hit}, {"f", :nearly}, {"c", :miss}, ...]

  """
  def get_board(%Game{board: board}), do: board

  @doc """
  Add the player move to the given game.

  ## Examples

      iex> put_player_move(game, player_guess)
      {:ok, %Game{}}

      iex> put_player_move(game, player_guess)
      {:error, {:game_over, :won}, %Game{}}

  """
  def put_player_move(game, player_guess) do
    unless over?(game) do
      player_guess = normalize_string(player_guess)

      game =
        game
        |> put_move(player_guess)
        |> put_moves_made()
        |> put_result(player_guess)

      {:ok, game}
    else
      {:error, :game_over}
    end
  end

  @doc """
  Returns whether the game is over.

  ## Examples

      iex> over?(game)
      true

  """
  def over?(%Game{result: result}), do: not is_nil(result)

  defp put_name(opts), do: Keyword.put_new_lazy(opts, :name, &puid/0)

  defp put_puzzle(opts) do
    Keyword.put_new_lazy(opts, :puzzle, fn ->
      default_puzzle_size = Map.get(Game.__struct__(), :puzzle_size)

      opts
      |> Keyword.get(:puzzle_size, default_puzzle_size)
      |> Pordle.Dictionary.get()
      |> normalize_string()
    end)
  end

  defp put_player(opts), do: Keyword.put_new_lazy(opts, :player, &puid/0)

  defp put_board(
         %Game{moves_allowed: moves_allowed, puzzle_size: puzzle_size, board: board} = game
       ) do
    cond do
      is_nil(board) ->
        size = 1..(moves_allowed * puzzle_size)

        board =
          for(_row <- size, into: [], do: {nil, :empty})
          |> Enum.chunk_every(puzzle_size)

        Map.put(game, :board, board)

      true ->
        game
    end
  end

  defp put_move(%Game{puzzle: puzzle, moves_made: moves_made} = game, player_guess) do
    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parse_move(puzzle, player_guess))
    end)
  end

  defp put_moves_made(game), do: Map.update!(game, :moves_made, &(&1 + 1))

  defp put_result(%Game{board: board, puzzle: puzzle} = game, player_guess) do
    Map.update!(game, :result, fn result ->
      cond do
        puzzle == player_guess ->
          :won

        board_full?(board) ->
          :lost

        true ->
          result
      end
    end)
  end

  defp board_full?(board) do
    not (board
         |> List.flatten()
         |> Enum.any?(fn {char, _type} ->
           is_nil(char)
         end))
  end

  defp parse_move(puzzle, answer) do
    Enum.with_index(answer, fn char, index ->
      cond do
        char == Enum.at(puzzle, index) ->
          {char, :hit}

        char in puzzle and count_in_rest(answer, char, index) > count_in(puzzle, char) ->
          {char, :miss}

        char in puzzle ->
          {char, :nearly}

        true ->
          {char, :miss}
      end
    end)
  end

  defp count_in_rest(answer, char, index) do
    answer
    |> Enum.slice(index..-1)
    |> count_in(char)
  end

  defp count_in(list, char), do: Enum.count(list, &(&1 == char))

  defp normalize_string(string) do
    string
    |> String.downcase()
    |> String.trim()
    |> String.codepoints()
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
