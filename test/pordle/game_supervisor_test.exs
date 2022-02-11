defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias Pordle.{
    GameSupervisor,
    GameRegistry,
    GameServer
  }

  test "start_child/1 starts a new game server process" do
    assert [] = Registry.lookup(GameRegistry, "my game")

    assert {:ok, server} = GameSupervisor.start_child(name: "my game")
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, "my game"})
  end
end
