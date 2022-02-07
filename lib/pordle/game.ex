defmodule Pordle.Game do
  @moduledoc """
  A Pordle game.

  """
  alias Pordle.Game

  @enforce_keys [:name, :answer]

  defstruct [
    :name,
    :rows,
    :cols,
    :board,
    :current_move,
    :player,
    :answer,
  ]

  @default_opts [rows: 6, cols: 5, current_move: 0]

  @doc """
  Initializes a new game struct.

  ## Examples

      iex> Game.new()
      %Game{name: "OpMIz...", cols: 5}

      iex> Game.new(cols: 6)
      %Game{name: "OpMIz...", cols: 6}

  """
  def new(opts \\ []) do
    opts =
      @default_opts
      |> Keyword.merge(opts)
      |> Keyword.put(:name, puid())

    __MODULE__
    |> struct!(opts)
    |> put_board()
  end

  @doc """
  Add the player move to the given game.

  ## Examples

      iex> put_player_move(game, player_guess)
      %Game{board: []}

  """
  def put_player_move(%Game{answer: answer, current_move: current_move} = game, player_guess) do
    case over?(game) do
      true ->
        {:error, :game_over}

      _ ->
        game
        |> Map.update!(:board, fn board ->
          List.replace_at(board, current_move, parse_move(answer, player_guess))
        end)
        |> Map.update!(:current_move, &(&1 + 1))
    end
  end

  @doc """
  Returns whether the game is over.

  ## Examples

      iex> Game.over?(%Game{})
      false

  """
  def over?(%Game{current_move: current_move, rows: rows}), do: not(current_move < rows)

  @doc """
  Generates a probably unique string with the given `size`.

  ## Examples

      iex> Game.puid()
      "OpMIz26yIKK5YPN"

      iex> Game.puid(6)
      "sIK9bx"

  """
  def puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp put_board(%Game{board: board} = game) when is_list(board), do: game

  defp put_board(%Game{rows: rows, cols: cols} = game) do
    size = 1..(rows * cols)

    board =
      for(_row <- size, into: [], do: nil)
      |> Enum.chunk_every(cols)

    Map.put(game, :board, board)
  end

  defp parse_move(puzzle_answer, player_answer) do
    puzzle_answer = String.codepoints(puzzle_answer)
    player_answer = String.codepoints(player_answer)

    Enum.with_index(player_answer, fn char, index ->
      cond do
        char == Enum.at(puzzle_answer, index) ->
          {char, :hit}

        char in puzzle_answer ->
          {char, :nearly}

        true ->
          {char, :miss}
      end
    end)
  end
end
