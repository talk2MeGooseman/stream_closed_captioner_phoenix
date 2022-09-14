defmodule StreamClosedCaptionerPhoenix.Jobs.SendChatReminder do
  use Oban.Worker, queue: :default

  # %{broadcaster_user_id: "talk2megooseman", broadcaster_user_login: "talk2megooseman"}
  # |> StreamClosedCaptionerPhoenix.Jobs.SendChatReminder.new(schedule_in: 10)
  # |> Oban.insert()

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "broadcaster_user_id" => broadcaster_user_id,
          "broadcaster_user_login" => broadcaster_user_login
        }
      }) do
    IO.puts("Sending chat reminder for #{broadcaster_user_login}")

    if !StreamClosedCaptionerPhoenixWeb.ActivePresence.is_channel_active?(broadcaster_user_id) ||
         true do
      TwitchBot.say(
        broadcaster_user_login,
        "Hey @#{broadcaster_user_login}, here is your friendly reminder to turn on Stream Closed Captioner."
      )

      TwitchBot.disconnect(broadcaster_user_login)
    else
      TwitchBot.disconnect(broadcaster_user_login)
      {:discard, "Channel is active"}
    end
  end
end
