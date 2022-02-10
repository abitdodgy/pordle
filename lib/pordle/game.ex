defmodule Pordle.Game do
  @moduledoc """
  This module contains game logic and state.

  """
  alias Pordle.Game

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          puzzle: nonempty_charlist(),
          puzzle_size: non_neg_integer() | 5,
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won,
          board: list()
        }

  defstruct name: nil,
            board: nil,
            puzzle: nil,
            result: nil,
            puzzle_size: 5,
            moves_allowed: 6,
            moves_made: 0

  @doc """
  Initializes a new game struct.

  """
  def new(opts \\ []) do
    __MODULE__
    |> struct!(opts)
    |> init_board()
  end

  @doc """
  Validates and adds the player move to the given game.

  ## Examples

      iex> put_player_move(game, "smart")
      {:ok, %Game{}}

      iex> put_player_move(%Game{puzzle_size: 5}, "word") # length(word) < puzzle_size 
      {:error, :invalid_move}

      iex> put_player_move(game, player_guess)
      {:error, :game_over}

  """
  def put_player_move(game, player_guess) do
    cond do
      finished?(game) ->
        {:error, :game_over}

      not valid_move?(game, player_guess) ->
        {:error, :invalid_move}

      true ->
        game =
          game
          |> put_move(player_guess)
          |> put_result(player_guess)

        {:ok, game}
    end
  end

  @doc """
  Returns whether the game is finished. If the game has a result, it's considered finished.

  ## Examples

      iex> finished?(%Game{result: :won})
      true

      iex> finished?(%Game{result: nil})
      false

  """
  def finished?(%Game{result: result}), do: not is_nil(result)

  defp valid_move?(%Game{puzzle: puzzle}, player_guess) do
    String.length(puzzle) == String.length(player_guess)
  end

  defp init_board(
         %Game{moves_allowed: moves_allowed, puzzle_size: puzzle_size, board: board} = game
       ) do
    cond do
      is_nil(board) ->
        size = 1..(moves_allowed * puzzle_size)

        for(_row <- size, into: [], do: {nil, :empty})
        |> Enum.chunk_every(puzzle_size)
        |> then(fn board -> Map.put(game, :board, board) end)

      true ->
        game
    end
  end

  defp put_move(%Game{puzzle: puzzle, moves_made: moves_made} = game, player_guess) do
    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parse_move(puzzle, player_guess))
    end)
    |> Map.update!(:moves_made, &(&1 + 1))
  end

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
    puzzle = to_list(puzzle)
    answer = to_list(answer)

    answer
    |> Enum.with_index()
    |> Enum.reduce([], fn {char, index}, acc ->
      cond do
        char == Enum.at(puzzle, index) ->
          {char, :hit}

        char in puzzle and count_in_answer(acc, char) < count_in_puzzle(puzzle, char) ->
          {char, :nearly}

        char in puzzle ->
          {char, :miss}

        true ->
          {char, :miss}
      end
      |> then(fn result -> acc ++ [result] end)
    end)
  end

  defp count_in_answer(answer, char), do: Enum.count(answer, fn {i, _type} -> i == char end)

  defp count_in_puzzle(puzzle, char), do: Enum.count(puzzle, & &1 == char)

  defp to_list(string), do: String.codepoints(string)
end
