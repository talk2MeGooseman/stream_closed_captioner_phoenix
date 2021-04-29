defmodule StreamClosedCaptionerPhoenixWeb.Schema do
  use Absinthe.Schema

  alias StreamClosedCaptionerPhoenixWeb.{Schema, Resolvers}
  alias StreamClosedCaptionerPhoenix.Bits

  import_types(Schema.AccountsTypes)
  import_types(Schema.Types.Custom.JSON)
  import_types(Schema.Types.Custom.DateTime)

  # Add import type here. Example
  # import_types(Schema.ProductTypes)

  @desc "Information of a channel"
  object :channel_info do
    field :uid, :string

    field :bits_balance, :bits_balance do
      resolve(&Resolvers.Bits.bits_balance/3)
    end

    field :translations, :translations do
      resolve(&Resolvers.Settings.get_translations_info/3)
    end
  end

  @desc "Users bits balance"
  object :bits_balance do
    field :balance, :integer
  end

  @desc "Translations information"
  object :translations do
    field :languages, :json
    field :activated, :boolean
    field :created_at, :datetime
  end

  @desc "Information the a Twitch transaction"
  object :twitch_transaction do
    field :response, :string
  end

  query do
    # Add queries here. Example
    import_fields(:accounts_queries)

    @desc "Fetch the current status of a channel"
    field :channel_info, :channel_info do
      arg(:id, non_null(:id))

      resolve(&Resolvers.AccountsOauth.get_channel_info/3)
    end
  end

  mutation do
    # Add mutations here. Example
    field :process_bits_transaction, type: :twitch_transaction do
      # once decded has transaction information
      arg(:chanel_id, :string)

      resolve(&process_bits_transaction/3)
    end
  end

  def process_bits_transaction(_parent, %{channel_id: channel_id}, %{
        context: %{decoded_token: decoded_token}
      }) do
    Bits.process_bits_transaction(channel_id, decoded_token)
  end

  def process_bits_transaction(_parent, _args, _resolution) do
    {:error, "Access denied, missing or invalid token"}
  end
end
