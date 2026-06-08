defmodule StreamClosedCaptionerPhoenixWeb.ShowcaseHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("showcase/*")

  @doc "Fill a Twitch thumbnail URL template with concrete width/height."
  def set_stream_thumnail_dimensions(url, width, height) do
    url
    |> String.replace("{width}", width)
    |> String.replace("{height}", height)
  end

  @doc ~S"""
  Compact viewer count for the card badge: `4820 -> "4.8K"`, `970 -> "970"`.
  """
  def format_viewers(count) when is_binary(count) do
    case Integer.parse(count) do
      {n, _rest} -> format_viewers(n)
      :error -> count
    end
  end

  def format_viewers(count) when is_integer(count) and count >= 1000 do
    (count / 1000)
    |> Float.round(1)
    |> Float.to_string()
    |> String.replace_suffix(".0", "")
    |> Kernel.<>("K")
  end

  def format_viewers(count), do: to_string(count)

  @doc "Up-to-two-letter initials for a streamer avatar."
  def initials(name) do
    name
    |> to_string()
    |> String.replace(~r/[^A-Za-z]/, "")
    |> String.slice(0, 2)
    |> String.upcase()
  end

  @avatar_palette ~w(#9146FF #22D3EE #F59E0B #34D399)

  @doc """
  Deterministic gradient background for a streamer avatar, derived from the
  name so a given streamer always gets the same colour regardless of sort.
  """
  def avatar_style(name) do
    color = Enum.at(@avatar_palette, rem(:erlang.phash2(name), length(@avatar_palette)))
    "background: linear-gradient(150deg, #{color}, color-mix(in srgb, #{color} 50%, #000))"
  end
end
