defmodule GoosemanApp do
  def fetch_supporters() do
    Neuron.Config.set(url: "https://guzman.codes/api")

    query = """
    {
      twitch {
        broadcasterSubscriptions(broadcasterId: "120750024") {
          user {
            id
            profileImageUrl
            displayName
            description
          }
          tier
        }
      }
      patreon {
        campaignMembers {
          fullName
          currentlyEntitledAmountCents
          campaignLifetimeSupportCents
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
