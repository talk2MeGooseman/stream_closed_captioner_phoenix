defmodule Twitch.Helix do
  import Twitch.Helpers

  alias Twitch.Helix.{Stream, Transaction}
  @max_per_request 100

  def get_streams(client_id, access_token, user_ids) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{access_token}"}
    ]

    data =
      encode_url_and_params("https://api.twitch.tv/helix/streams", %{
        user_ids: user_ids
      })
      |> HTTPoison.get!(headers)
      |> get_in(["body"])
      |> Jason.decode!()

    cursor = get_in(data, ["pagination", "cursor"])

    if is_number(cursor) do
      [
        get_streams(client_id, access_token, user_ids, cursor)
        | Enum.map(get_in(data, ["data"]), &Stream.new/1)
      ]
    else
      Enum.map(get_in(data, ["data"]), &Stream.new/1)
    end
  end

  def get_streams(client_id, access_token, user_ids, cursor) do
    []
  end

  def get_transactions(client_id, access_token, id) do
    headers = [
      {"Content-Type", "application/json"},
      {"Client-Id", client_id},
      {"Authorization", "Bearer #{access_token}"}
    ]

    data =
      encode_url_and_params("https://api.twitch.tv/helix/extensions/transactions", %{
        extension_id: client_id,
        id: id
      })
      |> HTTPoison.get!(headers)
      |> get_in(["body"])
      |> Jason.decode!()

    Enum.map(get_in(data, ["data"]), &Transaction.new/1)
  end
end
