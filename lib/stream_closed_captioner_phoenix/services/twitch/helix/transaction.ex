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
    :product_data
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          timestamp: String.t(),
          broadcaster_id: String.t(),
          broadcaster_login: String.t(),
          broadcaster_name: String.t(),
          user_id: String.t(),
          user_login: String.t(),
          user_name: String.t(),
          product_type: String.t(),
          product_data: String.t()
        }
  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    %{res | product_data: ProductData.new(res.product_data)}
  end
end
