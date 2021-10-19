defmodule StreamClosedCaptionerPhoenixWeb.SupportersView do
  use StreamClosedCaptionerPhoenixWeb, :view

  @spec filter_twitch_subscribers(list()) :: list()
  def filter_twitch_subscribers(subscribes) do
    Enum.filter(subscribes, fn x -> x["user"]["displayName"] != "Talk2meGooseman" end)
  end

  @spec filter_patreon_subscribers(list()) :: list()
  def filter_patreon_subscribers(subscribes) do
    Enum.filter(subscribes, fn x -> !is_nil(x["patronStatus"]) end)
  end

  def snakeCaseToText(text) do
    String.replace(text, "_", " ")
  end
end
