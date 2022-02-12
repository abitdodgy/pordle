defmodule Pordle.GameTest do
  use ExUnit.Case, async: true

  alias Pordle.Game

  # setup do
  #   game_name = :rand.uniform(10000)

  #   on_exit fn ->
  #     [{server, _}] = Registry.lookup(GameRegistry, {GameServer, game_name})
  #     Process.exit(server, :normal)
  #   end

  #   {:ok, game_name: game_name}
  # end

  # test "new/1 returns a new game struct and populates board", %{game_name: game_name} do
  #   assert %Game{} = Game.new([name: game_name, moves_allowed: 3, puzzle_size: 6, puzzle:])
  # end
end
