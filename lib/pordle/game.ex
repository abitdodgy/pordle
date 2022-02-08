defmodule Pordle.Game do
  @moduledoc """
  A Pordle game.

  """
  alias Pordle.Game

  @enforce_keys [:name, :answer]

  defstruct([
    :name,
    :player,
    :answer,
    word_size: 5,
    moves_allowed: 6,
    moves_made: 0,
    status: :active,
    board: []
  ])

  @doc """
  Initializes a new game struct.

  ## Examples

      iex> Game.new()
      %Game{name: "OpMIz...", word_size: 5}

      iex> Game.new(word_size: 6)
      %Game{name: "OpMIz...", word_size: 6}

  """
  def new(opts \\ []) do
    opts = Keyword.put(opts, :name, puid())

    __MODULE__
    |> struct!(opts)
    |> init_board()
    |> tap(&IO.inspect(&1))
  end

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

  @doc """
  Returns a list of the chars used by the player.

  ## Examples

      iex> get_chars_used(game)
      [{"a", :hit}, {"s", :nearly}, ...]

  """
  def get_chars_used(%Game{board: board}) do
    board
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  @doc """
  Add the player move to the given game.

  ## Examples

      iex> put_player_move(game, player_guess)
      %Game{}

  """
  def put_player_move(%Game{status: status} = game, player_guess) do
    cond do
      status in [:won, :lost] ->
        {:error, {:game_over, status}}

      true ->
        game
        |> put_board(player_guess)
        |> put_moves_made()
        |> put_status(player_guess)
    end
  end

  defp put_board(%Game{answer: answer, moves_made: moves_made} = game, player_guess) do
    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parse_move(answer, player_guess))
    end)
  end

  defp put_moves_made(game) do
    Map.update!(game, :moves_made, &(&1 + 1))
  end

  defp put_status(%Game{answer: answer} = game, player_guess) do
    Map.update!(game, :status, fn _status ->
      cond do
        answer == player_guess ->
          :won

        over?(game) ->
          :lost

        true ->
          :active
      end
    end)
  end

  defp over?(%Game{moves_made: moves_made, moves_allowed: moves_allowed}),
    do: not (moves_made < moves_allowed)

  defp init_board(%Game{moves_allowed: moves_allowed, word_size: word_size, board: []} = game) do
    size = 1..(moves_allowed * word_size)

    board =
      for(_row <- size, into: [], do: nil)
      |> Enum.chunk_every(word_size)

    Map.put(game, :board, board)
  end

  defp init_board(game), do: game

  defp parse_move(puzzle, answer) do
    puzzle =
      puzzle
      |> String.downcase()
      |> String.codepoints()

    answer =
      answer
      |> String.downcase()
      |> String.codepoints()

    Enum.with_index(answer, fn char, index ->
      cond do
        char == Enum.at(puzzle, index) ->
          {char, :hit}

        char in puzzle ->
          {char, :nearly}

        true ->
          {char, :miss}
      end
    end)
  end
end
