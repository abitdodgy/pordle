defmodule Pordle.Game do
  @moduledoc """
  A Pordle game.

  """
  defstruct [name: Ecto.UUID.generate(), rows: 6, cols: 5]
end
