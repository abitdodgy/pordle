defmodule Pordle.GameTest do
  use ExUnit.Case, async: true

  alias Pordle.Game

  describe "new/1" do
    test "builds a new game struct from the given opts" do
      game = Game.new(name: "game", puzzle: "crate", moves_allowed: 2)

      assert %Game{
               result: nil,
               finished?: false,
               name: "game",
               puzzle: "crate",
               moves_made: 0,
               moves_allowed: 2,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: %{}
             } = game
    end
  end

  describe "play_move/2" do
    setup do
      game = Game.new(name: "game", puzzle: "crate", moves_allowed: 2)

      assert_initial_state(game)

      {:ok, game: game}
    end

    test "with a valid move", %{game: game} do
      {:ok, %Game{} = game} = play_move(game, "heart")

      assert %Game{
               result: nil,
               finished?: false,
               moves_made: 1,
               moves_allowed: 2,
               board: [
                 [miss: "h", nearly: "e", hit: "a", nearly: "r", nearly: "t"],
                 _
               ],
               keyboard: %{
                 "h" => :miss,
                 "e" => :nearly,
                 "a" => :hit,
                 "r" => :nearly,
                 "t" => :nearly
               }
             } = game
    end

    test "with a winning move", %{game: game} do
      {:ok, %Game{} = game} = play_move(game, "crate")

      assert %Game{
               result: :won,
               finished?: true,
               moves_made: 1,
               moves_allowed: 2,
               board: [
                 [hit: "c", hit: "r", hit: "a", hit: "t", hit: "e"],
                 _
               ],
               keyboard: %{"c" => :hit, "r" => :hit, "a" => :hit, "t" => :hit, "e" => :hit}
             } = game
    end

    test "when moves run out", %{game: game} do
      {:ok, %Game{} = game} = play_move(game, "heart")
      {:ok, %Game{} = game} = play_move(game, "slate")

      assert %Game{
               result: :lost,
               finished?: true,
               moves_made: 2,
               moves_allowed: 2,
               board: [
                 [miss: "h", nearly: "e", hit: "a", nearly: "r", nearly: "t"],
                 [miss: "s", miss: "l", hit: "a", hit: "t", hit: "e"]
               ],
               keyboard: %{
                 "h" => :miss,
                 "e" => :hit,
                 "a" => :hit,
                 "r" => :nearly,
                 "t" => :hit,
                 "s" => :miss,
                 "l" => :miss
               }
             } = game
    end

    test "when move is too short", %{game: game} do
      {:error, :invalid_move} = play_move(game, "foo")
    end

    test "when move is too long ignores last char", %{game: game} do
      {:error, :word_not_found} = play_move(game, "foobar")
    end

    test "evaluates double letters correctly" do
      game = Game.new(name: "game", puzzle: "tarty", moves_allowed: 9)

      {:ok, %Game{} = game} = play_move(game, "tarot")
      {:ok, %Game{} = game} = play_move(game, "tatts")
      {:ok, %Game{} = game} = play_move(game, "stott")
      {:ok, %Game{} = game} = play_move(game, "sttty")
      {:ok, %Game{} = game} = play_move(game, "stttt")
      {:ok, %Game{} = game} = play_move(game, "tstft")
      {:ok, %Game{} = game} = play_move(game, "tsttf")
      {:ok, %Game{} = game} = play_move(game, "ttttf")
      {:ok, %Game{} = game} = play_move(game, "tarty")

      assert %Game{
               board: [
                 [hit: "t", hit: "a", hit: "r", miss: "o", nearly: "t"],
                 [hit: "t", hit: "a", miss: "t", hit: "t", miss: "s"],
                 [miss: "s", nearly: "t", miss: "o", hit: "t", miss: "t"],
                 [miss: "s", nearly: "t", miss: "t", hit: "t", hit: "y"],
                 [miss: "s", nearly: "t", miss: "t", hit: "t", miss: "t"],
                 [hit: "t", miss: "s", nearly: "t", miss: "f", miss: "t"],
                 [hit: "t", miss: "s", miss: "t", hit: "t", miss: "f"],
                 [hit: "t", miss: "t", miss: "t", hit: "t", miss: "f"],
                 [hit: "t", hit: "a", hit: "r", hit: "t", hit: "y"]
               ]
             } = game
    end

    defp assert_initial_state(game) do
      assert %Game{
               result: nil,
               finished?: false,
               moves_made: 0,
               keyboard: %{},
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = game
    end
  end

  describe "insert_char/2" do
    setup do
      {:ok, game: Game.new(name: "game", puzzle: "crate", moves_allowed: 1)}
    end

    test "appends `char` to board with type `:full`", %{game: game} do
      {:ok, %Game{} = game} = Game.insert_char(game, "h")

      assert %Game{
               board: [
                 [full: "h", empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = game

      {:ok, %Game{} = game} = Game.insert_char(game, "e")

      assert %Game{
               board: [
                 [full: "h", full: "e", empty: nil, empty: nil, empty: nil]
               ]
             } = game
    end

    test "does not overflow", %{game: game} do
      {:ok, game} = Game.insert_char(game, "h")
      {:ok, game} = Game.insert_char(game, "e")
      {:ok, game} = Game.insert_char(game, "a")
      {:ok, game} = Game.insert_char(game, "r")
      {:ok, game} = Game.insert_char(game, "t")

      {:ok, %Game{} = game} = Game.insert_char(game, "s")

      assert %Game{
               board: [
                 [full: "h", full: "e", full: "a", full: "r", full: "t"]
               ]
             } = game
    end
  end

  describe "delete_char/1" do
    setup do
      game = Game.new(name: "game", puzzle: "crate", moves_allowed: 1)

      {:ok, game} = Game.insert_char(game, "h")
      {:ok, game} = Game.insert_char(game, "e")

      {:ok, game: game}
    end

    test "deletes most recent `char` with type `:full` from board", %{game: game} do
      assert %Game{
               board: [
                 [full: "h", full: "e", empty: nil, empty: nil, empty: nil]
               ]
             } = game

      {:ok, %Game{} = game} = Game.delete_char(game)

      assert %Game{
               board: [
                 [full: "h", empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = game
    end

    test "does not overflow", %{game: game} do
      assert %Game{
               board: [
                 [full: "h", full: "e", empty: nil, empty: nil, empty: nil]
               ]
             } = game

      {:ok, %Game{} = game} = Game.delete_char(game)
      {:ok, %Game{} = game} = Game.delete_char(game)
      {:ok, %Game{} = game} = Game.delete_char(game)

      assert %Game{
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = game
    end
  end

  defp play_move(game, move) do
    move = String.codepoints(move)

    Enum.reduce(move, game, fn char, acc ->
      acc
      |> Game.insert_char(char)
      |> then(fn {_, game} -> game end)
    end)
    |> Game.play_move()
  end
end
