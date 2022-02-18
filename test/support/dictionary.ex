defmodule Pordle.Test.Dictionary do
  @moduledoc false

  @dictionary ~w[
    foo
    foobar

  	slate
  	heart
    crate

    bubble
    bbblue
  ]

  @doc false
  def valid?(entry) do
    Enum.member?(@dictionary, entry)
  end
end
