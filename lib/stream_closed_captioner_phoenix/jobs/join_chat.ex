defmodule StreamClosedCaptionerPhoenix.Jobs.JoinChat do
  use Oban.Worker, queue: :default

  # %{channel: "talk2megooseman"}
  # |> StreamClosedCaptionerPhoenix.Jobs.JoinChat.new(schedule_in: 10)
  # |> Oban.insert()

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "broadcaster_user_id" => broadcaster_user_id,
          "broadcaster_user_login" => broadcaster_user_login
        }
      }) do
    if !StreamClosedCaptionerPhoenixWeb.ActivePresence.is_channel_active?(broadcaster_user_id) do
      TwitchBot.connect_to(broadcaster_user_login)

      %{
        "broadcaster_user_id" => broadcaster_user_id,
        "broadcaster_user_login" => broadcaster_user_login
      }
      |> StreamClosedCaptionerPhoenix.Jobs.SendChatReminder.new(schedule_in: 300)
      |> Oban.insert()
    else
      {:discard, "Channel is active"}
    end
  end
end
