defmodule StreamClosedCaptionerPhoenix.Twitch do
  alias StreamClosedCaptionerPhoenix.Twitch.Stream

  def fetch_streams(client_id, access_token) do
    headers = [
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{access_token}"}
    ]

    response = HTTPoison.get!("https://api.twitch.tv/helix/streams", headers)

    response.body
    |> Jason.decode!()
    |> Enum.map(&Stream.new/1)
  end
end
