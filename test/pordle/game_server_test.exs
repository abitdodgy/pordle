defmodule Pordle.GameServerTest do
  use ExUnit.Case, async: true

  alias Pordle.{GameServer, Game}

  describe "start_link/1" do
    setup do
      opts = [name: Integer.to_string(:rand.uniform(10000))]
      {:ok, opts: opts}
    end

    test "starts a new game server with the given name and default options", %{
      opts: [name: name] = opts
    } do
      assert {:ok, server} = GameServer.start_link(opts)

      assert %Game{
               name: ^name,
               puzzle: puzzle,
               puzzle_size: puzzle_size,
               moves_made: 0,
               moves_allowed: 6
             } = :sys.get_state(server)

      assert is_integer(puzzle_size)

      assert String.length(name) > 0
      assert String.length(puzzle) == puzzle_size

      Process.exit(server, :normal)
    end

    test "accepts a custom `puzzle_size` and `moves_allowed` as options", %{opts: opts} do
      assert {:ok, server} = GameServer.start_link(opts ++ [puzzle_size: 3, moves_allowed: 1])

      assert %Game{
               puzzle: puzzle,
               puzzle_size: 3,
               moves_allowed: 1,
               board: [
                 [
                   nil: :empty,
                   nil: :empty,
                   nil: :empty
                 ]
               ]
             } = :sys.get_state(server)

      assert String.length(puzzle) == 3

      Process.exit(server, :normal)
    end

    test "ignores `puzzle_size` when a `puzzle` is provided", %{opts: opts} do
      assert {:ok, server} = GameServer.start_link(opts ++ [puzzle: "amazing", puzzle_size: 3])

      %Game{puzzle: "amazing", puzzle_size: 7} = :sys.get_state(server)

      Process.exit(server, :normal)
    end
  end

  describe "play_move/2" do
    setup do
      {:ok, server} =
        GameServer.start_link(name: :rand.uniform(10000), puzzle: "crate", moves_allowed: 1)

      on_exit(fn ->
        Process.exit(server, :normal)
      end)

      {:ok, server: server}
    end

    test "when move is valid updates server state", %{server: server} do
      assert_initial_state(server)

      {:ok, %Game{} = state} = GameServer.play_move(server, "heart")

      assert %Game{
               moves_made: 1,
               board: [
                 [
                   {"h", :miss},
                   {"e", :nearly},
                   {"a", :hit},
                   {"r", :nearly},
                   {"t", :nearly}
                 ]
               ],
               keys: [{"h", :miss}, {"e", :nearly}, {"a", :hit}, {"r", :nearly}, {"t", :nearly}]
             } = state
    end

    test "when move is not in dictionary", %{server: server} do
      assert_initial_state(server)

      {:error, :word_not_found} = GameServer.play_move(server, "there")
    end

    test "when move is not the correct length", %{server: server} do
      assert_initial_state(server)

      {:error, :invalid_move} = GameServer.play_move(server, "foo")
      {:error, :invalid_move} = GameServer.play_move(server, "foobar")
    end

    test "sanitises input", %{server: server} do
      assert_initial_state(server)

      {:ok, %Game{} = state} = GameServer.play_move(server, " SLatE ")

      assert %Game{
               board: [
                 [
                   {"s", :miss},
                   {"l", :miss},
                   {"a", :hit},
                   {"t", :hit},
                   {"e", :hit}
                 ]
               ],
               keys: [{"s", :miss}, {"l", :miss}, {"a", :hit}, {"t", :hit}, {"e", :hit}]
             } = state
    end
  end

  describe "play_move/2 process handling" do
    setup do
      {:ok, server} =
        GameServer.start_link(name: :rand.uniform(10000), puzzle: "crate", moves_allowed: 2)

      {:ok, server: server}
    end

    test "shuts down process when game is won", %{server: server} do
      assert Process.alive?(server)

      {:ok, _state} = GameServer.play_move(server, "crate")
      refute Process.alive?(server)
    end

    test "shuts down process when game is lost", %{server: server} do
      assert Process.alive?(server)

      {:ok, _state} = GameServer.play_move(server, "slate")
      assert Process.alive?(server)

      {:ok, _state} = GameServer.play_move(server, "slate")
      refute Process.alive?(server)
    end
  end

  defp assert_initial_state(server) do
    assert %Game{
             moves_made: 0,
             keys: [],
             board: [[nil: :empty, nil: :empty, nil: :empty, nil: :empty, nil: :empty]]
           } = :sys.get_state(server)
  end

  describe "get_state/1" do
    setup do
      {:ok, server} =
        GameServer.start_link(name: :rand.uniform(10000), puzzle: "crate", moves_allowed: 1)

      on_exit(fn ->
        Process.exit(server, :normal)
      end)

      {:ok, server: server}
    end

    test "returns the state for the given server", %{server: server} do
      {:ok, %Game{} = state} = GameServer.get_state(server)
      assert ^state = :sys.get_state(server)
    end
  end
end
