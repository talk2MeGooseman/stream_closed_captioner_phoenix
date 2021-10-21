defmodule GoosemanApp do
  def fetch_supporters() do
    Neuron.Config.set(url: "https://gooseman-app.azurewebsites.net/graphql/twitch")

    query = """
    {
      helix {
        me {
          subscribers {
            tier
            user {
              displayName
              id
              profilePictureUrl
              description
            }
          }
        }
      }
      patreon {
        patrons {
          status
          totalHistoricalAmountCents
          user {
            id
            fullName
            imageUrl
            url
            about
          }
        }
      }
    }
    """

    case Neuron.query(query) do
      {:ok, %{body: body}} -> {:ok, body}
      _ -> {:error, "Request failed"}
    end
  end
end
