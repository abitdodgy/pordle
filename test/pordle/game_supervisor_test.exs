defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias Pordle.{
    GameSupervisor,
    GameRegistry,
    GameServer
  }

  setup do
    game_name = :rand.uniform(10000)

    on_exit(fn ->
      [{server, _}] = Registry.lookup(GameRegistry, {GameServer, game_name})
      Process.exit(server, :normal)
    end)

    {:ok, game_name: game_name}
  end

  test "start_child/1 starts a new game server process", %{game_name: game_name} do
    assert [] = Registry.lookup(GameRegistry, {GameServer, game_name})

    assert {:ok, server} = GameSupervisor.start_child(name: game_name)
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, game_name})
  end
end
