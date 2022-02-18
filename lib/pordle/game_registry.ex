defmodule Pordle.GameRegistry do
  @moduledoc """
  Keeps track of active game servers in the registry.

  """

  @doc """
  Returns the process registry for the given `id`.

  ## Examples

      iex> via_tuple({GameServer, "1"})
      {:via, Registry, {GameRegistry, {GameServer, "1"}}}

  """
  def via_tuple(id) do
    {:via, Registry, {__MODULE__, id}}
  end

  def lookup(name) do
    Registry.lookup(__MODULE__, name)
  end
end
