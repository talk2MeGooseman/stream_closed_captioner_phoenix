defmodule StreamClosedCaptionerPhoenixWeb.ActivePresence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """

  # alias StreamClosedCaptionerPhoenix.Accounts

  use Phoenix.Presence,
    otp_app: :stream_closed_captioner_phoenix,
    pubsub_server: StreamClosedCaptionerPhoenix.PubSub

  # def fetch(_topic, presences) do
  #   users = presences |> Map.keys() |> Accounts.get_users_map()

  #   for {key, %{metas: metas}} <- presences, into: %{} do
  #     {key, %{metas: metas, user: users[String.to_integer(key)]}}
  #   end
  # end
end
