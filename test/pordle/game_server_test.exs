defmodule Pordle.GameServerTest do
  use ExUnit.Case

  alias Pordle.{GameServer, Game}

  describe "start_link/1" do
    setup do
      {:ok, name: "game", puzzle: "crate"}
    end

    test "starts a new game server with the given options", %{
      name: name,
      puzzle: puzzle
    } do
      assert {:ok, pid} = GameServer.start_link(name: name, puzzle: puzzle)

      assert %Game{
               name: ^name,
               puzzle: ^puzzle,
               moves: [],
               moves_made: 0,
               moves_allowed: 6,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 _,
                 _,
                 _,
                 _,
                 _
               ],
               keyboard: []
             } = :sys.get_state(pid)
    end

    test "accepts `moves_allowed` as an option", %{name: name, puzzle: puzzle} do
      assert {:ok, pid} = GameServer.start_link(name: name, puzzle: puzzle, moves_allowed: 1)

      assert %Game{
               name: ^name,
               puzzle: ^puzzle,
               moves: [],
               moves_made: 0,
               moves_allowed: 1,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: []
             } = :sys.get_state(pid)
    end
  end

  describe "play_move/2" do
    setup do
      {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate", moves_allowed: 2)
      {:ok, name: "game", pid: pid}
    end

    test "when move is valid updates server state", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = state} = GameServer.play_move(name, "heart")

      assert %Game{
               moves: ["heart"],
               moves_made: 1,
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
             } = state
    end

    test "when move is a winning move", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = state} = GameServer.play_move(name, "crate")

      assert %Game{
               moves: ["crate"],
               moves_made: 1,
               result: :won,
               board: [
                 [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [
                 {:hit, "c"},
                 {:hit, "r"},
                 {:hit, "a"},
                 {:hit, "t"},
                 {:hit, "e"}
               ]
             } = state
    end

    test "when move is a losing move", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = _state} = GameServer.play_move(name, "slate")
      {:ok, %Game{} = state} = GameServer.play_move(name, "slate")

      assert %Game{
               moves: ["slate", "slate"],
               moves_made: 2,
               result: :lost,
               board: [
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [
                 {:miss, "s"},
                 {:miss, "l"},
                 {:hit, "a"},
                 {:hit, "t"},
                 {:hit, "e"}
               ]
             } = state
    end

    test "when move is not in dictionary", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:error, :word_not_found} = GameServer.play_move(name, "there")
    end

    test "when move is not the correct length", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:error, :invalid_move} = GameServer.play_move(name, "foo")
      {:error, :invalid_move} = GameServer.play_move(name, "foobar")

      assert_initial_state(pid)
    end

    test "sanitises input", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = state} = GameServer.play_move(name, " SLatE ")

      assert %Game{
               moves: ["slate"],
               board: [
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}]
             } = state
    end
  end

  defp assert_initial_state(pid) do
    assert %Game{
             moves: [],
             moves_made: 0,
             keyboard: [],
             board: [
               [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
               _
             ]
           } = :sys.get_state(pid)
  end

  describe "get_state/1" do
    setup do
      {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate")
      {:ok, name: "game", pid: pid}
    end

    test "returns the state for the given server", %{name: name, pid: pid} do
      {:ok, %Game{} = state} = GameServer.get_state(name)
      assert ^state = :sys.get_state(pid)
    end
  end

  describe "exit/1" do
    test "shuts down the process for the given server" do
      {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate")

      assert Process.alive?(pid)
      assert :ok = GameServer.exit("game")

      # TODO
      # 
      # Without `Process.sleep` this assertion will fail since `Process.alive?/1` returns
      # before GenServer has shutdown.
      # 
      # Find a better way to test this.
      Process.sleep 50
      refute Process.alive?(pid)
    end
  end
end
