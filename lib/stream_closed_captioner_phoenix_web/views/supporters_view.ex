defmodule StreamClosedCaptionerPhoenixWeb.SupportersView do
  use StreamClosedCaptionerPhoenixWeb, :view

  @spec filter_twitch_subscribers(list()) :: list()
  def filter_twitch_subscribers(subscribes) do
    Enum.filter(subscribes, fn x -> x["user"]["displayName"] != "Talk2meGooseman" end)
  end

  @spec filter_patreon_subscribers(list()) :: list()
  def filter_patreon_subscribers(subscribes) do
    Enum.filter(subscribes, fn x ->
      x["stauts"] != "declined" || x["totalHistoricalAmountCents"] > 0
    end)
  end

  def getPoliteStatus(text) do
    case text do
      "valid" -> "Active Patron"
      _ -> "Former Patron"
    end
  end
end
