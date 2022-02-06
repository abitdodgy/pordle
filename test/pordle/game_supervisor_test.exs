defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias Pordle.{
    GameSupervisor,
    GameRegistry,
    GameServer
  }

  test "start_child/1 starts a new game server process" do
    assert [] = Registry.lookup(GameRegistry, "1")

    assert {:ok, server} = GameSupervisor.start_child([id: "1"])
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, "1"})
  end
end
