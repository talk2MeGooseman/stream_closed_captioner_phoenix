defmodule StreamClosedCaptionerPhoenixWeb.CaptionSourceLive.Show do
  @moduledoc """
  Public OBS browser-source page that renders a streamer's live captions over
  a transparent background. Looked up by secret caption source token, no auth.

  Appearance is driven entirely by query params (all optional):

    * `font_size` — px, 10..120 (default 32)
    * `color` — 3/6 digit hex text color (default FFFFFF)
    * `bg` — 3/6 digit hex background color (default 000000)
    * `bg_opacity` — 0..100 (default 70)
    * `align` — left | center | right (default left)
    * `uppercase` — true | false (defaults to the streamer's text_uppercase setting)
    * `lines` — visible lines, 1..10 (default 3)
    * `font` — sans | serif | mono (default sans)

  Every value is validated/clamped server-side and re-emitted from parsed
  primitives, so raw params never reach the style attribute.
  """
  use StreamClosedCaptionerPhoenixWeb, :live_view

  alias StreamClosedCaptionerPhoenix.Settings

  @max_final_chars 500

  @font_stacks %{
    "sans" => "system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    "serif" => "Georgia, 'Times New Roman', Times, serif",
    "mono" => "'JetBrains Mono', 'Courier New', monospace"
  }

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    stream_settings = Settings.get_stream_settings_by_caption_source_token!(token)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        StreamClosedCaptionerPhoenix.PubSub,
        "caption_source:#{stream_settings.user_id}"
      )
    end

    {:ok,
     socket
     |> assign(:stream_settings, stream_settings)
     |> assign(:page_title, "Captions")
     |> assign(:interim, "")
     |> assign(:final_text, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, :style, build_style(params, socket.assigns.stream_settings))}
  end

  @impl true
  def handle_info({:caption_source_payload, payload}, socket) do
    delay = socket.assigns.stream_settings.caption_delay || 0

    if delay > 0 do
      Process.send_after(self(), {:apply_caption, payload}, delay * 1000)
      {:noreply, socket}
    else
      {:noreply, apply_caption(socket, payload)}
    end
  end

  def handle_info({:apply_caption, payload}, socket) do
    {:noreply, apply_caption(socket, payload)}
  end

  defp apply_caption(socket, payload) do
    final = Map.get(payload, :final) || ""
    interim = Map.get(payload, :interim) || ""

    socket
    |> assign(:final_text, append_final(socket.assigns.final_text, final))
    |> assign(:interim, interim)
  end

  defp append_final(existing, ""), do: existing

  defp append_final(existing, final) do
    [existing, final]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> trim_leading_words(@max_final_chars)
  end

  # Drops whole words from the front until the text fits the cap, so old
  # captions scroll away instead of growing the assign forever.
  defp trim_leading_words(text, max_chars) when byte_size(text) <= max_chars, do: text

  defp trim_leading_words(text, max_chars) do
    case String.split(text, " ", parts: 2) do
      [_word, rest] -> trim_leading_words(rest, max_chars)
      [word] -> String.slice(word, -max_chars, max_chars)
    end
  end

  defp build_style(params, stream_settings) do
    font_size = parse_int(params["font_size"], 32, 10, 120)
    {r, g, b} = parse_hex_color(params["color"], {255, 255, 255})
    {bg_r, bg_g, bg_b} = parse_hex_color(params["bg"], {0, 0, 0})
    bg_opacity = parse_int(params["bg_opacity"], 70, 0, 100)
    align = parse_enum(params["align"], ~w(left center right), "left")
    lines = parse_int(params["lines"], 3, 1, 10)
    font_stack = Map.get(@font_stacks, params["font"], @font_stacks["sans"])

    uppercase? =
      case params["uppercase"] do
        value when value in ["true", "1"] -> true
        value when value in ["false", "0"] -> false
        _ -> stream_settings.text_uppercase
      end

    %{
      font_size: font_size,
      color: "rgb(#{r}, #{g}, #{b})",
      background: "rgba(#{bg_r}, #{bg_g}, #{bg_b}, #{bg_opacity / 100})",
      align: align,
      lines: lines,
      font_stack: font_stack,
      text_transform: if(uppercase?, do: "uppercase", else: "none")
    }
  end

  defp caption_box_style(style) do
    [
      "background: #{style.background}",
      "color: #{style.color}",
      "font-family: #{style.font_stack}",
      "font-size: #{style.font_size}px",
      "text-align: #{style.align}",
      "text-transform: #{style.text_transform}",
      "line-height: 1.4",
      "max-height: calc(#{style.lines} * 1.4em + 0.8em)",
      "overflow: hidden",
      "display: flex",
      "flex-direction: column",
      "justify-content: flex-end",
      "overflow-wrap: break-word",
      "word-break: break-word",
      "border-radius: 4px",
      "padding: 0.4em 0.6em",
      "max-width: 100%"
    ]
    |> Enum.join("; ")
  end

  defp parse_int(value, default, min, max) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int |> max(min) |> min(max)
      _ -> default
    end
  end

  defp parse_int(_value, default, _min, _max), do: default

  defp parse_enum(value, allowed, default) do
    if value in allowed, do: value, else: default
  end

  defp parse_hex_color(value, default) when is_binary(value) do
    case String.trim_leading(value, "#") do
      <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> ->
        parse_rgb_pairs(r, g, b, default)

      <<r::binary-size(1), g::binary-size(1), b::binary-size(1)>> ->
        parse_rgb_pairs(r <> r, g <> g, b <> b, default)

      _ ->
        default
    end
  end

  defp parse_hex_color(_value, default), do: default

  defp parse_rgb_pairs(r, g, b, default) do
    with {r, ""} <- Integer.parse(r, 16),
         {g, ""} <- Integer.parse(g, 16),
         {b, ""} <- Integer.parse(b, 16) do
      {r, g, b}
    else
      _ -> default
    end
  end
end
