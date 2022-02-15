defmodule Pordle.Dictionary do
  @moduledoc """
  A behaviour to generate and validate puzzle words for the game.

  """

  @doc """
  Returns a new puzzle word.

  """
  @callback new(Integer.t) :: String.t

  @doc """
  Validates a puzzle word against the dictionary.

  """
  @callback valid?(String.t) :: Boolean
end
