defmodule Pordle.CLI do
  @moduledoc """                                             

  ██████╗  ██████╗ ██████╗ ██████╗ ██╗     ███████╗
  ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
  ██████╔╝██║   ██║██████╔╝██║  ██║██║     █████╗  
  ██╔═══╝ ██║   ██║██╔══██╗██║  ██║██║     ██╔══╝  
  ██║     ╚██████╔╝██║  ██║██████╔╝███████╗███████╗
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

  Welcome to Pordle CLI. Type `:help` for help. Type `:quit` to quit. Good luck!
  """
  alias Pordle.Game

  @commands %{
    ":quit" => "Quits the game",
    ":help" => "Available commands"
  }

  @doc """
  Entry point for the game.

  """
  def main(argv) do
    IO.puts(@moduledoc)

    {:ok, server} =
      argv
      |> parse_args()
      |> start_server()

    server
    |> Pordle.get_game()
    |> render_board()

    receive_command(server)
  end

  defp parse_args(args) do
    {options, _, _} =
      OptionParser.parse(args,
        switches: [puzzle_size: :integer, player: :string, moves_allowed: :integer, puzzle: :string]
      )

    options
  end

  defp start_server(opts), do: Pordle.create_game(opts)

  defp render_board(%Game{board: board, moves_made: moves_made, moves_allowed: moves_allowed}) do
    IO.puts(" 😀 > Your board after #{highlight(moves_made)} round(s):\n")

    Enum.each(board, fn row ->
      IO.write("     > \s\s\s")
      Enum.each(row, &draw_cell/1)
      IO.puts("\n")
    end)

    board
    |> List.flatten()
    |> Enum.reject(fn {char, _type} -> is_nil(char) end)
    |> Enum.uniq_by(fn {char, _type} -> char end)
    |> then(fn board ->
      unless Enum.empty?(board) do
        IO.puts(" 😀 > Your keyboard after #{highlight(moves_made)} round(s):\n")
        IO.write("     > \s\s\s")
        Enum.each(board, &draw_cell/1)
        IO.puts("\n")
      end
    end)

    IO.puts(" 😀 > You have #{highlight(moves_allowed - moves_made)} guess(es) remaning.\n")
  end

  defp receive_command(server) do
    IO.gets(" 🧐 > Type your guess and press return: ")
    |> String.trim()
    |> execute_command(server)
  end

  def execute_command(":quit" = cmd, _server) do
    @commands
    |> Map.get(cmd)
    |> IO.puts()
  end

  def execute_command(":help" = cmd, _server) do
    @commands
    |> Map.get(cmd)
    |> IO.puts()
  end

  def execute_command(guess, server) do
    IO.puts("\n 🤔 > You guessed #{highlight(guess)}.\n")
    play_move(server, guess)
  end

  defp play_move(server, guess) do
    server
    |> Pordle.put_player_move(guess)
    |> case do
      {:ok, %Game{result: :won, moves_made: moves_made} = game} ->
        render_board(game)
        IO.puts(" 🤩 > Congratulations, you won in #{highlight(moves_made)} guess(es)! 🏆\n")
        IO.puts(" 👋 > Game over.\n")

      {:ok, %Game{result: :lost} = game} ->
        render_board(game)
        IO.puts(" 😭 > Bad luck, you lost! 💩\n")
        IO.puts(" 👋 > Game over.\n")

      {:ok, game} ->
        render_board(game)
        receive_command(server)

      {:error, :invalid_move} ->
        IO.puts(" 🙄 > The word #{highlight(guess)} is not the correct length.\n")
        receive_command(server)

      {:error, :word_not_found} ->
        IO.puts(" 🤭 > The word #{highlight(guess)} was not found in the dictionary.\n")
        receive_command(server)

      {:error, :game_over} ->
        IO.puts(" 🤔 > Game over.\n")
    end
  end

  defp highlight(char) do
    IO.ANSI.light_red() <> "#{char}" <> IO.ANSI.reset()
  end

  defp draw_cell({char, type}) do
    char = String.upcase("#{char}")

    char =
      case type do
        :hit ->
          IO.ANSI.green_background() <> " #{char} "
        :miss ->
          IO.ANSI.color_background(2, 2, 2) <> " #{char} "
        :empty ->
          IO.ANSI.color_background(4, 4, 4) <> "\s\s\s"
        :nearly ->
          IO.ANSI.light_cyan_background() <> " #{char} "
      end <> IO.ANSI.reset() <> " "

    IO.write(char)
  end
end
