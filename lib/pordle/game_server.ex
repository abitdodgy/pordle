defmodule Pordle.GameServer do
  @moduledoc """
  Pordle game server.

  """
  use GenServer, restart: :temporary

  def start_link(opts) do
    id = Keyword.get(opts, :id, :rand.uniform(1000))
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  defp via_tuple(game_id) do
    Pordle.GameRegistry.via_tuple({__MODULE__, game_id})
  end
end
