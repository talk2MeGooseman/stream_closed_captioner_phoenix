defmodule StreamClosedCaptionerPhoenixWeb.Schema do
  use Absinthe.Schema

  alias StreamClosedCaptionerPhoenixWeb.Schema
  alias StreamClosedCaptionerPhoenix.{Accounts, Bits, Settings}

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
    field :total, :integer
  end

  @desc "Translations information"
  object :translations do
    field :languages, :json
    field :activated, :boolean
    field :created_at, :datetime
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

  #  mutation do
  # Add mutations here. Example
  # import_fields(:create_product)
  #  end

  def get_channel_info(_, %{id: id}, _resolution) do
    case StreamClosedCaptionerPhoenix.Accounts.get_user_by_channel_id(%{
           id: id,
           preload: [:bits_balance, :translate_languages]
         }) do
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
       languages: Settings.get_formatted_translate_languages_by_user(user),
       activated: !is_nil(debit),
       created_at: Map.get(debit || %{}, :created_at)
     }}
  end

  defp active_debit(%{id: id}) do
    StreamClosedCaptionerPhoenix.Bits.get_user_active_debit(id)
  end
end
