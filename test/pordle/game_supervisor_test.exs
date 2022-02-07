defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias Pordle.{
    GameSupervisor,
    GameRegistry,
    GameServer,
    Game
  }

  setup do
    {:ok, game: Game.new(name: "123")}
  end

  test "start_child/1 starts a new game server process", %{game: %Game{name: name} = game} do
    assert [] = Registry.lookup(GameRegistry, name)

    assert {:ok, server} = GameSupervisor.start_child(game)
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, name})
  end
end
