defmodule Pordle.Dictionary do
  @dicionary ~w[
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
  ]

  def get do
    Enum.random(@dicionary)
  end

  def is_entry(entry) do
    case Enum.member?(@dicionary, entry) do
      true ->
        {:ok, entry}

      false ->
        {:error, :word_not_found}
    end
  end
end
