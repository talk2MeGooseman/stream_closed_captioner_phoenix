defmodule StreamClosedCaptionerPhoenixWeb.Schema do
  import AbsintheCache, only: [cache_resolve: 1, cache_resolve: 2]

  use Absinthe.Schema

  alias StreamClosedCaptionerPhoenixWeb.{Schema, Resolvers}

  def middleware(middleware, _field, _object) do
    [NewRelic.Absinthe.Middleware | middleware]
  end

  import_types(Schema.AccountsTypes)
  import_types(Schema.Types.Custom.JSON)
  import_types(Schema.Types.Custom.DateTime)

  # Add import type here. Example
  # import_types(Schema.ProductTypes)

  @desc "Information of a channel"
  object :channel_info do
    field :uid, :string

    field :bits_balance, :bits_balance do
      cache_resolve(&Resolvers.Bits.bits_balance/3, ttl: 300, max_ttl_offset: 10)
    end

    field :translations, :translations do
      cache_resolve(&Resolvers.Settings.get_translations_info/3, ttl: 300, max_ttl_offset: 10)
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
    field :message, :json
  end

  @desc "Twitch Captions"
  object :twitch_caption do
    field :interim, :string
    field :final, :string
    field :translations, :json
  end

  query do
    # Add queries here. Example
    import_fields(:accounts_queries)

    @desc "Fetch the current status of a channel"
    field :channel_info, :channel_info do
      arg(:id, non_null(:id))

      cache_resolve(&Resolvers.AccountsOauth.get_channel_info/3, ttl: 300, max_ttl_offset: 10)
    end
  end

  mutation do
    # Add mutations here. Example
    field :process_bits_transaction, type: :twitch_transaction do
      arg(:channel_id, non_null(:id))

      resolve(&Resolvers.Bits.process_bits_transaction/3)
    end
  end

  subscription do
    field :new_twitch_caption, :twitch_caption do
      arg(:channel_id, non_null(:id))

      # The topic function is used to determine what topic a given subscription
      # cares about based on its arguments. You can think of it as a way to tell the
      # difference between
      # subscription {
      #   newTwitchCaption(channel_id: "1") { content }
      # }
      #
      # and
      #
      # If needed, you can also provide a list of topics:
      #   {:ok, topic: ["absinthe-graphql/absinthe", "elixir-lang/elixir"]}
      # Absinthe.Subscription.publish(StreamClosedCaptionerPhoenixWeb.Endpoint, %{ interim: "hello", final: "final" }, new_twitch_caption: "1")
      config(fn args, _ ->
        {:ok, topic: args.channel_id}
      end)
    end
  end
end
