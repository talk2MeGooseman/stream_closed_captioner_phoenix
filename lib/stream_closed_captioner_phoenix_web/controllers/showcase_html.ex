defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("showcase/*")

  def set_stream_thumnail_dimensions(url, width, height) do
    url
    |> String.replace("{width}", width)
    |> String.replace("{height}", height)
  end
end
