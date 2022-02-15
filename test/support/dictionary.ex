defmodule Pordle.Test.Dictionary do
  @moduledoc """
  An implementation of `Pordle.Dictionary` behaviour for testing.

  """
  @behaviour Pordle.Dictionary

  @dictionary ~w[
    foo
    foobar

  	slate
  	heart
    crate

    bubble
    bbblue
  ]

  @impl true
  def new(size) do
    @dictionary
    |> Enum.filter(&(String.length(&1) == size))
    |> Enum.random()
  end

  @impl true
  def valid?(entry) do
    Enum.member?(@dictionary, entry)
  end
end