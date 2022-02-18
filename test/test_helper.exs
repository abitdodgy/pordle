ExUnit.start()

defmodule Pordle.Test.Helpers do
  def get_name do
    1000
    |> :rand.uniform()
    |> Integer.to_string()
  end
end
