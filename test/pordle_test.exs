defmodule PordleTest do
  use ExUnit.Case

  alias Pordle.{GameRegistry, GameServer}

  setup do
    game_name = :rand.uniform(10000)

    on_exit(fn ->
      [{server, _}] = Registry.lookup(GameRegistry, {GameServer, game_name})
      Process.exit(server, :normal)
    end)

    {:ok, game_name: game_name}
  end

  test "create_game/1 returns a game server", %{game_name: game_name} do
    assert {:ok, server} = Pordle.create_game(name: game_name)
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, game_name})
  end
end
