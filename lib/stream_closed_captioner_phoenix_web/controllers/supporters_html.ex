defmodule StreamClosedCaptionerPhoenixWeb.SupportersHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("supporters/*")

  @spec filter_twitch_subscribers(list()) :: list()
  def filter_twitch_subscribers(subscribes) do
    Enum.filter(subscribes, fn x -> x["user"]["displayName"] != "Talk2meGooseman" end)
  end

  @spec filter_patreon_subscribers(list()) :: list()
  def filter_patreon_subscribers(subscribes) do
    Enum.filter(subscribes, fn x ->
      x["campaignLifetimeSupportCents"] > 0
    end)
  end

  def get_polite_status(support_value) do
    case support_value > 0 do
      true -> "Active Patron"
      _ -> "Former Patron"
    end
  end
end
