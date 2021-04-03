defmodule Twitch.Helix.ProductData do
  alias Twitch.Helix.Cost

  defstruct [
    :sku,
    :cost,
    :display_name,
    :in_development
  ]

  @type t :: %__MODULE__{
          sku: String.t(),
          cost: non_neg_integer(),
          display_name: String.t(),
          in_development: boolean()
        }

  use ExConstructor

  def new(data, args \\ []) do
    res = super(data, args)
    %{res | cost: Cost.new(res.cost)}
  end
end
