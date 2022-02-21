defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case

  alias Pordle.{GameSupervisor, GameRegistry, GameServer}

  test "start_child/1 starts a new game server process" do
    assert [] = Registry.lookup(GameRegistry, {GameServer, "game"})

    assert {:ok, pid} = GameSupervisor.start_child(name: "game", puzzle: "crane")
    assert [{^pid, nil}] = Registry.lookup(GameRegistry, {GameServer, "game"})
  end
end
