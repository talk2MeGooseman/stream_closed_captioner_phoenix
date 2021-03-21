defmodule Twitch.Oauth do
  import Helpers

  alias Twitch.Helix.Credentials

  def get_client_access_token() do
    credentials = get_credentials()

    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", credentials.client_id}
    ]

    params = %{
      client_id: credentials.client_id,
      client_secret: credentials.client_secret,
      grant_type: "client_credentials",
      scope: ""
    }

    access_token =
      encode_url_and_params("https://id.twitch.tv/oauth2/token", params)
      |> HTTPoison.post!("", headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()
      |> get_in(["access_token"])

    Map.put(credentials, :access_token, access_token)
  end

  defp get_credentials,
    do: %Credentials{
      client_id: System.get_env("TWITCH_CLIENT_ID"),
      client_secret: System.get_env("TWITCH_CLIENT_SECRET")
    }
end
