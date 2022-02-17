defmodule Pordle.CLI.Narrator do
  @moduledoc """
  A helper module to narrate game play events to the CLI.

  """
  alias Pordle.CLI

  @lines [
    game_start: ~s"""

      ██████╗  ██████╗ ██████╗ ██████╗ ██╗     ███████╗
      ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
      ██████╔╝██║   ██║██████╔╝██║  ██║██║     █████╗  
      ██╔═══╝ ██║   ██║██╔══██╗██║  ██║██║     ██╔══╝  
      ██║     ╚██████╔╝██║  ██║██████╔╝███████╗███████╗
      ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

      Welcome to Pordle CLI. Type `:help` for help. Type `:quit` to quit. Good luck!
    """,
    help: ~s"""

    😀 Try to guess the word before you run out of guesses.

        - #{IO.ANSI.green_background() <> " A " <> IO.ANSI.reset()} The letter A is in the word and in the right place.
        - #{IO.ANSI.light_cyan_background() <> " A " <> IO.ANSI.reset()} The letter A is in the word but it's in the wrong place.
        - #{IO.ANSI.color_background(2, 2, 2) <> " A " <> IO.ANSI.reset()} The letter A is not in the word.

      Type `:quit` to quit the game.
    """,
    game_won: ~s"""
    🤩 Congratulations, you won in {{moves_made}} guess(es)! 🏆

      ██╗   ██╗ ██████╗ ██╗   ██╗    ██╗    ██╗██╗███╗   ██╗
      ╚██╗ ██╔╝██╔═══██╗██║   ██║    ██║    ██║██║████╗  ██║
       ╚████╔╝ ██║   ██║██║   ██║    ██║ █╗ ██║██║██╔██╗ ██║
        ╚██╔╝  ██║   ██║██║   ██║    ██║███╗██║██║██║╚██╗██║
         ██║   ╚██████╔╝╚██████╔╝    ╚███╔███╔╝██║██║ ╚████║
         ╚═╝    ╚═════╝  ╚═════╝      ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝

    👋 Game over!
    """,
    game_lost: ~S"""
    😭 Bad luck, you lost! 💩

      ██╗   ██╗ ██████╗ ██╗   ██╗    ██╗      ██████╗ ███████╗███████╗
      ╚██╗ ██╔╝██╔═══██╗██║   ██║    ██║     ██╔═══██╗██╔════╝██╔════╝
       ╚████╔╝ ██║   ██║██║   ██║    ██║     ██║   ██║███████╗█████╗  
        ╚██╔╝  ██║   ██║██║   ██║    ██║     ██║   ██║╚════██║██╔══╝  
         ██║   ╚██████╔╝╚██████╔╝    ███████╗╚██████╔╝███████║███████╗
         ╚═╝    ╚═════╝  ╚═════╝     ╚══════╝ ╚═════╝ ╚══════╝╚══════╝

    👋 Game over!
    """,
    game_keyboard: "😀 Your keyboard after {{moves_made}} round(s):",
    game_board: "😀 Your board after {{moves_made}} round(s):",
    make_guess: "🧐 Type your guess and press return: ",
    moves_remaining: "😀 You have {{moves_remaining}} guess(es) remaining.",
    player_move: "\n🤔 You guessed {{move}}.",
    invalid_move: "\n🙄 The word {{move}} is not the correct length.",
    word_not_found: "\n🤭 The word {{word}} was not found in the dictionary.",
    quit: "\n🤬 You suck!"
  ]

  @doc """
  Narrates the given line and its arguments.

  """
  def print_line(line, args \\ []) do
    line = Keyword.fetch!(@lines, line) <> "\n"

    Enum.reduce(args, line, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", highlight(value))
    end)
    |> IO.puts()
  end

  @doc """
  Accessor for `@lines`.

  """
  def get_line(line), do: Keyword.fetch!(@lines, line)

  defp highlight(char) do
    CLI.Theme.color(:highlight) <> "#{char}" <> IO.ANSI.reset()
  end
end
