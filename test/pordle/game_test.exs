defmodule Pordle.GameTest do
  use ExUnit.Case, async: true

  alias Pordle.Game

  describe "new/1" do
    test "calculates `puzzle_size` from the given `puzzle`" do
      assert %Game{puzzle: "crate"} = Game.new(name: "game", puzzle: "crate")
    end

    test "builds a new game struct from the given opts" do
      opts = [name: "game", puzzle: "crate", moves_allowed: 2]

      assert %Game{
               name: "game",
               puzzle: "crate",
               moves: [],
               moves_made: 0,
               moves_allowed: 2,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: []
             } = Game.new(opts)
    end
  end

  describe "play_move/2" do
    setup do
      {:ok, game: Game.new(name: "game", puzzle: "crate", moves_allowed: 2)}
    end

    test "with a valid move", %{game: game} do
      assert_initial_state(game)

      {:ok, %Game{} = game} = Game.play_move(game, "heart")

      assert %Game{
               result: nil,
               moves: ["heart"],
               moves_made: 1,
               moves_allowed: 2,
               board: [
                 [{:miss, "h"}, {:nearly, "e"}, {:hit, "a"}, {:nearly, "r"}, {:nearly, "t"}],
                 _
               ],
               keyboard: [
                 {:miss, "h"},
                 {:nearly, "e"},
                 {:hit, "a"},
                 {:nearly, "r"},
                 {:nearly, "t"}
               ]
             } = game
    end

    test "with a winning move", %{game: game} do
      assert_initial_state(game)

      {:ok, %Game{} = game} = Game.play_move(game, "crate")

      assert %Game{
               result: :won,
               moves: ["crate"],
               moves_made: 1,
               moves_allowed: 2,
               board: [
                 [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}]
             } = game
    end

    test "when moves run out", %{game: game} do
      assert_initial_state(game)

      {:ok, %Game{} = game} = Game.play_move(game, "heart")
      {:ok, %Game{} = game} = Game.play_move(game, "slate")

      assert %Game{
               result: :lost,
               moves: ["heart", "slate"],
               moves_made: 2,
               moves_allowed: 2,
               board: [
                 [{:miss, "h"}, {:nearly, "e"}, {:hit, "a"}, {:nearly, "r"}, {:nearly, "t"}],
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}]
               ],
               keyboard: [
                 {:miss, "h"},
                 {:nearly, "e"},
                 {:hit, "a"},
                 {:nearly, "r"},
                 {:nearly, "t"},
                 {:miss, "s"},
                 {:miss, "l"}
               ]
             } = game
    end

    test "when move is not the correct length", %{game: game} do
      assert_initial_state(game)

      {:error, :invalid_move} = Game.play_move(game, "foo")
      {:error, :invalid_move} = Game.play_move(game, "foobar")
    end

    test "evaluates double letters correctly" do
      game = Game.new(name: "foo", puzzle: "small", moves_allowed: 3)

      {:ok, %Game{} = game} = Game.play_move(game, "lllma")

      assert %Game{
               board: [
                 [{:nearly, "l"}, {:nearly, "l"}, {:miss, "l"}, _, _],
                 _,
                 _
               ]
             } = game

      # TODO: Add other scenarios.
      #
      # {:ok, %Game{} = game} = Game.play_move(game, "lllma")
      # assert %Game{
      #          board: [
      #            [{"l", :nearly}, {"l", :nearly}, {"l", :miss}, _, _], _, _
      #          ]
      #        } = game
      #
    end

    defp assert_initial_state(game) do
      assert %Game{
               moves: [],
               moves_made: 0,
               keyboard: [],
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = game
    end
  end
end
