defmodule StreamClosedCaptionerPhoenixWeb.Schema do
  use Absinthe.Schema

  alias StreamClosedCaptionerPhoenixWeb.Schema
  alias StreamClosedCaptionerPhoenix.{Accounts, Settings, Bits}

  import_types(Schema.AccountsTypes)
  import_types(Schema.Types.Custom.JSON)
  import_types(Schema.Types.Custom.DateTime)

  # Add import type here. Example
  # import_types(Schema.ProductTypes)

  @desc "Information of a channel"
  object :channel_info do
    field :uid, :string
    field :bits_balance, :bits_balance

    field :translations, :translations do
      resolve(&get_translations/3)
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

      resolve(&get_channel_info/3)
    end
  end

  mutation do
    # Add mutations here. Example
    field :activate_translations, type: :twitch_transaction do
      # once decded has transaction information
      arg(:chanel_id, :string)

      resolve(&activate_translations/3)
    end
  end

  def activate_translations(_parent, args, %{context: %{decoded_token: decoded_token}}) do
    transaction_id = ""
    # Validate that transaction has not already occurred
    case Bits.get_bits_transaction_by(transaction_id) do
      nil -> {:ok, %{response: "happy path"}}
      _transaction -> {:error, "Transaction #{transaction_id} is already recorded."}
    end

    # Get user associated to the transaction
    # Credit the account bits balance
  end

  def activate_translations(_parent, _args, _resolution) do
    {:error, "Access denied, missing or invalid token"}
  end

  def get_channel_info(_, %{id: id}, _resolution) do
    case StreamClosedCaptionerPhoenix.AccountsOauth.get_user_for_provider("twitch", id) do
      nil ->
        {:error, "Channel #{id} not found"}

      user ->
        {:ok, user}
    end
  end

  def get_translations(%Accounts.User{} = user, _, _resolution) do
    debit = active_debit(user)

    {:ok,
     %{
       languages: Settings.get_formatted_translate_languages_by_user(user.id),
       activated: !is_nil(debit),
       created_at: Map.get(debit || %{}, :created_at)
     }}
  end

  defp active_debit(%{id: id}) do
    StreamClosedCaptionerPhoenix.Bits.get_user_active_debit(id)
  end
end
