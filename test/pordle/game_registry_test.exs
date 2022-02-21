defmodule Pordle.GameRegistryTest do
  use ExUnit.Case

  test "via_tuple/1 returns a via tuple for the given game `name`" do
    via_tuple = Pordle.GameRegistry.via_tuple("name")
    assert {:via, _registry, {_registry_name, "name"}} = via_tuple
  end
end
