defmodule Pordle.Dictionary do
  @dictionary ~w[
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

  def get(size) do
    @dictionary
    |> Enum.filter(&(String.length(&1) == size))
    |> Enum.random()
  end

  def valid_entry?(entry), do: Enum.member?(@dictionary, entry)
end
