defmodule Twitch.Helix.Transaction do
  alias Twitch.Helix.ProductData

  defstruct [
    :id,
    :timestamp,
    :broadcaster_id,
    :broadcaster_login,
    :broadcaster_name,
    :user_id,
    :user_login,
    :user_name,
    :product_type,
    :product_data,
  ]
  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    %{res | product_data: ProductData.new(res.product_data)}
  end
end
