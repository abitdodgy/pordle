defmodule Pordle.Puzzle do
  @dictionary ~w[
    foo
    foobar

  	steam
  	storm
  	least
  	feast
  	smart
  	toast
  	holly
  	roast
  	skill
  	smite
  	blast
  	clear
  	smear
  	frost
  	slate
  	heart
    crate
    hello

    bubble
    bbblue
    uelbbb
    ublbbb
    ubbbbb
    breach
    speech
    ground
    scream
  ]

  def new(size) do
    @dictionary
    |> Enum.filter(&(String.length(&1) == size))
    |> Enum.random()
  end

  def valid?(entry), do: Enum.member?(@dictionary, entry)
end
