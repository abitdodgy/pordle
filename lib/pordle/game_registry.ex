defmodule Pordle.GameRegistry do
  @moduledoc """
  Keeps track of active game servers in the registry.

  """

  @doc """
  Returns the process registry for the given `id`.

  ## Examples

      iex> via_tuple("1")
      {:via, Registry, {GameRegistry, "1"}}

  """
  def via_tuple(id) do
    {:via, Registry, {__MODULE__, id}}
  end
end
