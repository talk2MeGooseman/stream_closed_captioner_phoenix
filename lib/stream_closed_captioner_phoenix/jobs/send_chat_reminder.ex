defmodule StreamClosedCaptionerPhoenix.Jobs.SendChatReminder do
  use Oban.Worker, queue: :default

  # %{broadcaster_user_id: "talk2megooseman", broadcaster_user_login: "talk2megooseman"} |> StreamClosedCaptionerPhoenix.Jobs.SendChatReminder.new(schedule_in: 10) |> Oban.insert()

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "broadcaster_user_id" => broadcaster_user_id,
          "broadcaster_user_login" => broadcaster_user_login
        },
        errors: errors
      }) do
    if Enum.any?(errors) do
      :cancel
    else
      if !StreamClosedCaptionerPhoenixWeb.ActivePresence.is_channel_active?(broadcaster_user_id) do
        Twitch.send_extension_chat_message(
          broadcaster_user_login,
          "Hey @#{broadcaster_user_login}, here is your friendly reminder to turn on Stream Closed Captioner."
        )
      end

      :ok
    end
  end
end
