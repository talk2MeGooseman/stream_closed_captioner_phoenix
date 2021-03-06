defmodule Twitch.Helix do
  import Helpers

  alias NewRelic.Instrumented.HTTPoison
  alias Twitch.HelixProvider
  alias Twitch.Helix.{Credentials, Stream, Transaction}
  @behaviour Twitch.HelixProvider

  @impl HelixProvider
  def get_streams(%Credentials{} = credentials, user_ids, cursor \\ nil) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", credentials.client_id},
      {"Authorization", "Bearer " <> credentials.access_token}
    ]

    user_tuple_list = Enum.map(user_ids, fn user_id -> {:user_id, user_id} end)

    data =
      encode_url_and_params("https://api.twitch.tv/helix/streams", user_tuple_list)
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    new_cursor = get_in(data, ["pagination", "cursor"])

    if is_binary(new_cursor) && new_cursor != cursor do
      get_streams(credentials, user_ids, cursor) ++
        Enum.map(get_in(data, ["data"]), &Stream.new/1)
    else
      Enum.map(get_in(data, ["data"]), &Stream.new/1)
    end
  end

  @impl HelixProvider
  def get_transactions(%Credentials{} = %{client_id: client_id, access_token: access_token}) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{access_token}"}
    ]

    data =
      encode_url_and_params("https://api.twitch.tv/helix/extensions/transactions", %{
        extension_id: client_id
      })
      |> HTTPoison.get!(headers)
      |> Map.fetch!(:body)
      |> Jason.decode!()

    Enum.map(get_in(data, ["data"]), &Transaction.new/1)
  end

  @impl HelixProvider
  def get_users_active_extensions(
        %Credentials{} = %{client_id: client_id, access_token: access_token}
      ) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{access_token}"}
    ]

    encode_url_and_params("https://api.twitch.tv/helix/users/extensions")
    |> HTTPoison.get!(headers)
    |> Map.fetch!(:body)
    |> Jason.decode!()
    |> Map.get("data")
  end
end
