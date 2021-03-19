defmodule Twitch.Helix.ProductData do
  alias Twitch.Helix.Cost

  defstruct [
    :sku,
    :cost,
    :display_name,
    :in_development
  ]
  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    %{res | cost: Cost.new(res.cost)}
  end
end
