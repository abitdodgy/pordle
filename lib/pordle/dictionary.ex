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
    breach
    speech
    ground
    scream
  ]

  def get(size) do
    @dictionary
    |> Enum.filter(&(String.length(&1) == size))
    |> Enum.random()
    |> tap(&IO.inspect/1)
  end

  def is_entry(entry) do
    case Enum.member?(@dictionary, entry) do
      true ->
        {:ok, entry}

      false ->
        {:error, :word_not_found}
    end
  end
end
