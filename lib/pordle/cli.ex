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

  @narrator [
    game_won: " 🤩 Congratulations, you won in {{moves_made}} guess(es)! 🏆\n",
    game_lost: " 😭 Bad luck, you lost! 💩\n",
    game_over: " 👋 Game over.\n",
    game_keys: " 😀 Your keyboard after {{moves_made}} round(s):\n",
    game_board: " 😀 Your board after {{moves_made}} round(s):\n",
    moves_remaining: " 😀 You have {{moves_remaining}} guess(es) remaining.\n",
    player_move: "\n 🤔 You guessed {{move}}.\n",
    invalid_move: "\n 🙄 The word {{move}} is not the correct length.\n",
    word_not_found: "\n 🤭 The word {{word}} was not found in the dictionary.\n",
    quit: "\n 🤬 You suck!\n",
    help: ~s"""

      Try to guess the word before you run out of guesses.

        - #{IO.ANSI.green_background() <> " A " <> IO.ANSI.reset()} The letter A is in the word and in the right place.

        - #{IO.ANSI.light_cyan_background() <> " A " <> IO.ANSI.reset()} The letter A is in the word but it's in the wrong place.

        - #{IO.ANSI.color_background(2, 2, 2) <> " A " <> IO.ANSI.reset()} The letter A is not in the word.

    """
  ]

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

  defp start_server(opts), do: Pordle.create_game(opts)

  defp receive_command(server) do
    IO.gets(" 🧐 Type your guess and press return: ")
    |> String.trim()
    |> execute_command(server)
  end

  defp execute_command(":quit", server) do
    narrate(:quit)
    Process.exit(server, :normal)
  end

  defp execute_command(":help", server) do
    narrate(:help)
    receive_command(server)
  end

  defp execute_command(guess, server) do
    play_move(server, guess)
  end

  defp narrate(line, args \\ []) do
    line = Keyword.get(@narrator, line)

    Enum.reduce(args, line, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", highlight(value))
    end)
    |> IO.puts()
  end

  defp render_board(%Game{
         board: board,
         moves_made: moves_made,
         moves_allowed: moves_allowed,
         result: result
       }) do
    narrate(:game_board, moves_made: moves_made)

    Enum.each(board, fn row ->
      IO.write("\t")
      Enum.each(row, &draw_cell/1)
      IO.puts("\n")
    end)

    board
    |> List.flatten()
    |> Enum.reject(fn {char, _type} -> is_nil(char) end)
    |> Enum.uniq_by(fn {char, _type} -> char end)
    |> then(fn board ->
      unless Enum.empty?(board) do
        narrate(:game_keys, moves_made: moves_made)
        IO.write("\t")
        Enum.each(board, &draw_cell/1)
        IO.puts("\n")
      end
    end)

    unless result, do: narrate(:moves_remaining, moves_remaining: moves_allowed - moves_made)
  end

  defp play_move(server, guess) do
    server
    |> Pordle.put_player_move(guess)
    |> case do
      {:ok, %Game{result: :won, moves_made: moves_made} = game} ->
        render_board(game)
        narrate(:game_won, moves_made: moves_made)

      {:ok, %Game{result: :lost} = game} ->
        render_board(game)
        narrate(:game_lost)

      {:ok, game} ->
        narrate(:player_move, move: guess)
        render_board(game)
        receive_command(server)

      {:error, :invalid_move} ->
        narrate(:invalid_move, move: guess)
        receive_command(server)

      {:error, :word_not_found} ->
        narrate(:word_not_found, word: guess)
        receive_command(server)

      {:error, :game_over} ->
        narrate(:game_over)
    end
  end

  defp highlight(char), do: IO.ANSI.light_red() <> "#{char}" <> IO.ANSI.reset()

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
