defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Settings do
  alias StreamClosedCaptionerPhoenix.{Accounts, Settings}

  def get_translations_info(%Accounts.User{} = user, _, _resolution) do
    debit = StreamClosedCaptionerPhoenix.Bits.get_user_active_debit(user.id)

    {:ok,
     %{
       languages: Settings.get_formatted_translate_languages_by_user(user.id),
       activated: !is_nil(debit),
       created_at: Map.get(debit || %{}, :created_at)
     }}
  end
end
