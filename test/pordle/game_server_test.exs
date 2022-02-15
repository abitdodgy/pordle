defmodule Pordle.GameServerTest do
  use ExUnit.Case, async: true

  alias Pordle.{GameServer, Game}

  describe "start_link/1" do
    setup do
      opts = [name: Integer.to_string(:rand.uniform(10000))]
      {:ok, opts: opts}
    end

    test "starts a new game server with the given name and default options", %{opts: [name: name] = opts} do
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

  describe "play_move/1" do
    setup do
      {:ok, server} = GameServer.start_link(name: :rand.uniform(10000), puzzle: "crate", moves_allowed: 1)

      on_exit fn ->
        Process.exit(server, :normal)
      end

      {:ok, server: server}
    end

    test "updates server state", %{server: server}  do
      assert %Game{moves_made: 0}} = 

      {:ok,
       %Game{
         moves_made: 1,
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
       }} = GameServer.play_move(server, "slate")

      Process.exit(server, :normal)
    end
  end

  # test "play_move/1 when move is not in dictionary" do
  #   assert {:ok, server} = GameServer.start_link(puzzle: "crate", moves_allowed: 2)

  #   {:error, :word_not_found} = GameServer.play_move(server, "there")

  #   Process.exit(server, :normal)
  # end

  # test "play_move/1 sanitizes move" do
  #   assert {:ok, server} = GameServer.start_link(puzzle: "crate", moves_allowed: 1)

  #   {:ok,
  #    %Game{
  #      board: [
  #        [
  #          {"s", :miss},
  #          {"l", :miss},
  #          {"a", :hit},
  #          {"t", :hit},
  #          {"e", :hit}
  #        ]
  #      ],
  #      keys: [{"s", :miss}, {"l", :miss}, {"a", :hit}, {"t", :hit}, {"e", :hit}]
  #    }} = GameServer.play_move(server, " SLatE ")

  #   Process.exit(server, :normal)
  # end

  # test "get_state/1 returns the state of the given server" do
  #   assert {:ok, server} = GameServer.start_link(puzzle: "foo", moves_allowed: 1)

  #   {:ok,
  #    %Game{
  #      puzzle: "foo",
  #      moves_allowed: 1,
  #      board: [
  #        [
  #          nil: :empty,
  #          nil: :empty,
  #          nil: :empty
  #        ]
  #      ]
  #    }} = GameServer.get_state(server)
  # end
end
