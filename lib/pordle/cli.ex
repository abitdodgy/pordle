defmodule Pordle.CLI do
  @moduledoc """
  Play Pordle using a Command Line Interface.

  """
  alias Pordle.{GameServer, Game, CLI.Narrator}

  @doc """
  Entry point for the game.

  """
  def main(argv) do
    Narrator.print_line(:game_start)

    {:ok, server} =
      argv
      |> parse_args()
      |> Pordle.create_game()

    {:ok, state} = GameServer.get_state(server)
    render_state(state)

    receive_command(server)
  end

  @doc """
  Renders the given character with a formatted background.

  """
  def cell(char, state),
    do: Pordle.CLI.Theme.color(state) <> " #{char} " <> IO.ANSI.reset() <> "\s"

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
         keyboard: keyboard,
         result: result
       }) do
    Narrator.print_line(:game_board, moves_made: moves_made)
    print_board(board)

    if not Enum.empty?(keyboard) do
      Narrator.print_line(:game_keyboard, moves_made: moves_made)
      print_keyboard(keyboard)
    end

    unless result,
      do: Narrator.print_line(:moves_remaining, moves_remaining: moves_allowed - moves_made)
  end

  defp receive_command(server) do
    :make_guess
    |> Narrator.get_line()
    |> IO.gets()
    |> String.trim()
    |> execute_command(server)
  end

  defp execute_command(":quit", server) do
    Narrator.print_line(:quit)
    Process.exit(server, :normal)
  end

  defp execute_command(":help", server) do
    Narrator.print_line(:help)
    receive_command(server)
  end

  defp execute_command(guess, server) do
    play_move(server, guess)
  end

  defp print_board(board) do
    Enum.each(board, fn row ->
      tab()
      Enum.each(row, &draw_cell/1)
      line()
    end)
  end

  defp print_keyboard(keyboard) do
    tab()
    Enum.each(keyboard, &draw_cell/1)
    line()
  end

  defp play_move(server, guess) do
    server
    |> GameServer.play_move(guess)
    |> case do
      {:ok, %Game{result: :won, moves_made: moves_made} = game} ->
        Narrator.print_line(:player_move, move: guess)
        render_state(game)
        Narrator.print_line(:game_won, moves_made: moves_made)

      {:ok, %Game{result: :lost} = game} ->
        Narrator.print_line(:player_move, move: guess)
        render_state(game)
        Narrator.print_line(:game_lost)

      {:ok, state} ->
        Narrator.print_line(:player_move, move: guess)
        render_state(state)
        receive_command(server)

      {:error, :invalid_move} ->
        Narrator.print_line(:invalid_move, move: guess)
        receive_command(server)

      {:error, :word_not_found} ->
        Narrator.print_line(:word_not_found, word: guess)
        receive_command(server)

      {:error, :game_over} ->
        Narrator.print_line(:game_over)
    end
  end

  defp draw_cell({char, state}) do
    char = if is_nil(char), do: "\s", else: String.upcase(char)

    char
    |> cell(state)
    |> IO.write()
  end

  defp tab(), do: IO.write("\t")
  defp line(), do: IO.puts("\n")
end
