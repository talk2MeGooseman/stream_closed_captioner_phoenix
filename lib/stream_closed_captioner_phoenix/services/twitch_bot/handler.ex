defmodule TwitchBot.Handler do
  use TMI.Handler

  defdelegate is_logged_on?(), to: TMI
  defdelegate say(chat, message), to: TMI, as: :message

  def connect(channels \\ []) do
    config = [
      user: "StreamClosedCaptioner",
      pass: System.get_env("TWITCH_CHAT_OAUTH"),
      chats: channels,
      handler: TwitchBot.Handler,
      capabilities: ['membership']
    ]

    TMI.supervisor_start_link(config)
  end

  @impl true
  # def handle_message("!" <> command, sender, chat) do
  #   case command do
  #     "dice" -> TMI.message(chat, Enum.random(~w(⚀ ⚁ ⚂ ⚃ ⚄ ⚅)))
  #     "echo " <> rest -> TMI.message(chat, rest)
  #     "dance" -> TMI.action(chat, "dances for #{sender}")
  #     _ -> TMI.message(chat, "unrecognized command")
  #   end
  # end

  def handle_message(message, sender, chat) do
    Logger.debug("Message in #{chat} from #{sender}: #{message}")
  end

  def handle_join(chat, user) do
    Logger.debug("!!!!!!!!! #{user} joined #{chat}")

    # Detect if streamclosedcaptioner joined the channel, update the list of joined channels in TwitchBot Gen Server
  end
end
