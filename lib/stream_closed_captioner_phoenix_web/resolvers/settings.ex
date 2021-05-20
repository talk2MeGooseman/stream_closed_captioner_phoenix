defmodule StreamClosedCaptionerPhoenixWeb.Resolvers.Settings do
  alias StreamClosedCaptionerPhoenix.{Accounts, Settings}

  def get_translations_info(%Accounts.User{} = user, _, _resolution) do
    debit = StreamClosedCaptionerPhoenix.Bits.get_user_active_debit(user.id)
    time = Map.get(debit || %{}, :created_at)

    {:ok,
     %{
       languages: Settings.get_formatted_translate_languages_by_user(user.id),
       activated: !is_nil(debit),
       created_at: format_datetime(time)
     }}
  end

  defp format_datetime(time) when is_nil(time), do: nil
  defp format_datetime(time), do: Timex.to_datetime(time, "Etc/UTC")
end
