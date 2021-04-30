defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseView do
  use StreamClosedCaptionerPhoenixWeb, :view

  def set_stream_thumnail_dimensions(url, width, height) do
    url
    |> String.replace("{width}", width)
    |> String.replace("{height}", height)
  end
end
