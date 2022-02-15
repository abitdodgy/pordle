defmodule Pordle.CLI.Theme do
  @colour_theme Application.fetch_env!(:pordle, :cli)[:theme]

  @doc """
  Returns the color for the given key.

  ## Examples

      iex> color(:highlight)
      "\e[91m"

  """

  def color(key), do: @colour_theme[key]
end
