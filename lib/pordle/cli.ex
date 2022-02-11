defmodule Pordle.CLI do
  @moduledoc """
  Play Pordle using a Command Line Interface.

  """
  alias Pordle.{GameServer, Game, CLI.Narrator}

  @colors [
    hit: IO.ANSI.green_background(),
    miss: IO.ANSI.color_background(2, 2, 2),
    nearly: IO.ANSI.light_cyan_background(),
    empty: IO.ANSI.color_background(4, 4, 4),
    highlight: IO.ANSI.light_red()
  ]

  @doc """
  Entry point for the game.

  """
  def main(argv) do
    Narrator.narrate(:game_start)

    {:ok, server} =
      argv
      |> parse_args()
      |> Pordle.create_game()

    {:ok, state} = GameServer.get_state(server)
    render_state(state)

    receive_command(server)
  end

  defp parse_args(args) do
    {options, _, _} =
      OptionParser.parse(args,
        switches: [
          puzzle_size: :integer,
          player: :string,
          moves_allowed: :integer,
          puzzle: :string
        ],
        aliases: [s: :puzzle_size, g: :moves_allowed, p: :puzzle]
      )

    options
  end

  defp render_state(%Game{
         board: board,
         moves_made: moves_made,
         moves_allowed: moves_allowed,
         keys: keys,
         result: result
       }) do
    Narrator.narrate(:game_board, moves_made: moves_made)
    print_board(board)

    if not Enum.empty?(keys) do
      Narrator.narrate(:game_keys, moves_made: moves_made)
      print_keys(keys)
    end

    unless result,
      do: Narrator.narrate(:moves_remaining, moves_remaining: moves_allowed - moves_made)
  end

  defp receive_command(server) do
    :make_guess
    |> Narrator.get_line()
    |> IO.gets()
    |> String.trim()
    |> execute_command(server)
  end

  defp execute_command(":quit", server) do
    Narrator.narrate(:quit)
    Process.exit(server, :normal)
  end

  defp execute_command(":help", server) do
    Narrator.narrate(:help)
    receive_command(server)
  end

  defp execute_command(guess, server) do
    play_move(server, guess)
  end

  defp print_board(board) do
    Enum.each(board, fn row ->
      IO.write("\t")
      Enum.each(row, &draw_cell/1)
      IO.puts("\n")
    end)
  end

  defp print_keys(keys) do
    IO.write("\t")
    Enum.each(keys, &draw_cell/1)
    IO.puts("\n")
  end

  defp play_move(server, guess) do
    server
    |> GameServer.play_move(guess)
    |> case do
      {:ok, %Game{result: :won, moves_made: moves_made} = game} ->
        Narrator.narrate(:player_move, move: guess)
        render_state(game)
        Narrator.narrate(:game_won, moves_made: moves_made)

      {:ok, %Game{result: :lost} = game} ->
        Narrator.narrate(:player_move, move: guess)
        render_state(game)
        Narrator.narrate(:game_lost)

      {:ok, state} ->
        Narrator.narrate(:player_move, move: guess)
        render_state(state)
        receive_command(server)

      {:error, :invalid_move} ->
        Narrator.narrate(:invalid_move, move: guess)
        receive_command(server)

      {:error, :word_not_found} ->
        Narrator.narrate(:word_not_found, word: guess)
        receive_command(server)

      {:error, :game_over} ->
        Narrator.narrate(:game_over)
    end
  end

  def draw_cell({char, state}) do
    char = if is_nil(char), do: "\s", else: String.upcase(char)

    char
    |> cell(state)
    |> IO.write()
  end

  def cell(char, state), do: @colors[state] <> " #{char} " <> IO.ANSI.reset() <> "\s"
end
