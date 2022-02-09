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

  @doc """
  Entry point for the game.

  """
  def main(argv) do
    IO.puts(@moduledoc)

    argv
    |> parse_args()
    |> start_server()
    |> render_board()
    |> get_guess()
  end

  defp parse_args(args) do
    {options, _, _} =
      OptionParser.parse(args,
        switches: [size: :integer, player: :string, moves: :integer, answer: :string]
      )

    options
  end

  defp start_server(opts), do: Pordle.create_game(opts)

  defp render_board({:ok, server}) do
    server
    |> Pordle.get_board()
    |> Enum.each(fn row ->
      Enum.each(row, fn char -> IO.write("#{draw_cell(char)} ") end)
      IO.puts("\n")
    end)

    IO.write("Your keyboard: ")

    server
    |> Pordle.get_chars_used()
    |> Enum.each(fn char -> IO.write("#{draw_cell(char)} ") end)

    IO.puts("\n")

    {:ok, server}
  end

  def get_guess({:ok, server}) do
    unless Pordle.game_over?(server) do
      guess =
        IO.gets("Type your guess and press return: ")
        |> String.trim()

      IO.puts("")

      server
      |> Pordle.put_player_move(guess)
      |> case do
        {:ok, _board} ->
          render_board({:ok, server}) |> get_guess()

        {:error, :word_not_found} ->
          guess = IO.ANSI.light_red() <> guess <> IO.ANSI.default_color()
          IO.puts("The word #{guess} was not found in the dictionary.")
          get_guess({:ok, server})
      end
    else
      case Pordle.get_game(server) do
        %Pordle.Game{status: :won, moves_made: moves_made} ->
          IO.puts("Congratulations, you won in #{moves_made} guesses!\n")

        %Pordle.Game{status: :lost} ->
          IO.puts("Bad luck, you lost!\n")
      end
    end
  end

  defp draw_cell({char, type}) do
    char = String.upcase("#{char}")

    case type do
      :hit ->
        IO.ANSI.green_background() <> " #{char} "

      :miss ->
        IO.ANSI.color_background(2, 2, 2) <> " #{char} "

      :nearly ->
        IO.ANSI.light_cyan_background() <> " #{char} "

      :empty ->
        IO.ANSI.color_background(4, 4, 4) <> "   "
    end <> IO.ANSI.reset()
  end
end
