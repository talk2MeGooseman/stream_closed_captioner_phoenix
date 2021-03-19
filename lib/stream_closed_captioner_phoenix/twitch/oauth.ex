defmodule Twitch.Oauth do
  def get_client_access_token(client_id, client_secret) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id}
    ]

    body =
      Jason.encode!(%{
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'client_credentials',
        scope: ''
      })

    response = HTTPoison.post!("https://id.twitch.tv/oauth2/token", body, headers)

    response.body
    |> Jason.decode!()
    |> get_in(["access_token"])
  end
end
