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

  A `settings` param controls the interactive settings tool: `1` forces it
  available everywhere (including OBS), `0` hides it entirely, and when absent
  the tool is available except inside OBS (detected client-side via
  `window.obsstudio` by the ObsDetect hook). The tool is pure client/URL
  state — it mutates nothing server-side and exposes nothing beyond what the
  token already grants.
  """
  use StreamClosedCaptionerPhoenixWeb, :live_view

  alias StreamClosedCaptionerPhoenix.Settings

  @max_final_chars 500

  @font_stacks %{
    "sans" => "system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    "serif" => "Georgia, 'Times New Roman', Times, serif",
    "mono" => "'JetBrains Mono', 'Courier New', monospace"
  }

  # Long enough to overflow the line clamp at default settings, so every
  # control's effect is visible while previewing.
  @sample_final "The quick brown fox jumps over the lazy dog while the streamer fine-tunes caption styling. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump! Sphinx of black quartz, judge my vow."
  @sample_interim "and this interim text is still being recognized"

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Settings.get_stream_settings_by_caption_source_token(token) do
      nil ->
        # Render a visible notice instead of a 404: in an OBS browser source a
        # 404 just looks like captions silently not working.
        {:ok,
         socket
         |> assign(:invalid_token, true)
         |> assign(:page_title, "Captions")}

      stream_settings ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(
            StreamClosedCaptionerPhoenix.PubSub,
            "caption_source:#{stream_settings.user_id}"
          )
        end

        {:ok,
         socket
         |> assign(:invalid_token, false)
         |> assign(:stream_settings, stream_settings)
         |> assign(:page_title, "Captions")
         |> assign(:interim, "")
         |> assign(:final_text, "")
         |> assign(:panel_open, false)
         |> assign(:obs_detected, false)
         |> assign(:settings_mode, :auto)
         |> assign(:settings_available, true)
         |> assign(:current_url, "")
         |> assign(:style, build_style(%{}, stream_settings))}
    end
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{invalid_token: true}} = socket) do
    {:noreply, socket}
  end

  def handle_params(params, url, socket) do
    settings_mode = parse_settings_mode(params["settings"])
    available = settings_available?(settings_mode, socket.assigns.obs_detected)

    {:noreply,
     socket
     |> assign(:style, build_style(params, socket.assigns.stream_settings))
     |> assign(:settings_mode, settings_mode)
     |> assign(:settings_available, available)
     |> assign(:panel_open, socket.assigns.panel_open and available)
     |> assign(:current_url, url)}
  end

  @impl true
  def handle_event("toggle_panel", _params, socket) do
    open? = not socket.assigns.panel_open and socket.assigns.settings_available
    {:noreply, assign(socket, :panel_open, open?)}
  end

  def handle_event("obs_detected", _params, socket) do
    available = settings_available?(socket.assigns.settings_mode, true)

    {:noreply,
     socket
     |> assign(:obs_detected, true)
     |> assign(:settings_available, available)
     |> assign(:panel_open, socket.assigns.panel_open and available)}
  end

  def handle_event("update_settings", params, socket) do
    stream_settings = socket.assigns.stream_settings
    query = overlay_query(params, stream_settings, socket.assigns.settings_mode)

    {:noreply,
     push_patch(socket, to: ~p"/captions/#{stream_settings.caption_source_token}?#{query}")}
  end

  defp parse_settings_mode("1"), do: :forced
  defp parse_settings_mode("0"), do: :disabled
  defp parse_settings_mode(_), do: :auto

  defp settings_available?(:forced, _obs_detected), do: true
  defp settings_available?(:disabled, _obs_detected), do: false
  defp settings_available?(:auto, obs_detected), do: not obs_detected

  # Runs the proposed form params through build_style and emits only the
  # validated primitives that differ from the empty-params style, so the URL
  # stays minimal, always holds clamped/valid values, and build_style remains
  # the single source of truth for both parsing and defaults (including the
  # streamer-dependent uppercase default).
  defp overlay_query(form_params, stream_settings, settings_mode) do
    proposed = build_style(form_params, stream_settings)
    defaults = build_style(%{}, stream_settings)

    params =
      [
        {"font_size", proposed.font_size, defaults.font_size},
        {"color", proposed.color_hex, defaults.color_hex},
        {"bg", proposed.bg_hex, defaults.bg_hex},
        {"bg_opacity", proposed.bg_opacity, defaults.bg_opacity},
        {"align", proposed.align, defaults.align},
        {"lines", proposed.lines, defaults.lines},
        {"font", proposed.font, defaults.font},
        {"uppercase", proposed.uppercase, defaults.uppercase}
      ]
      |> Enum.flat_map(fn
        {_key, value, value} -> []
        {key, value, _default} -> [{key, to_string(value)}]
      end)

    forced = if settings_mode == :forced, do: [{"settings", "1"}], else: []

    Map.new(params ++ forced)
  end

  defp display_final(true = _panel_open, _final_text), do: @sample_final
  defp display_final(false = _panel_open, final_text), do: final_text

  defp display_interim(true = _panel_open, _interim), do: @sample_interim
  defp display_interim(false = _panel_open, interim), do: interim

  attr(:panel_open, :boolean, required: true)
  attr(:style, :map, required: true)
  attr(:current_url, :string, required: true)

  defp settings_tool(assigns) do
    ~H"""
    <div
      id="caption-settings-ui"
      phx-hook="ObsDetect"
      class="nightwind-prevent-block fixed top-2 right-2 z-10 font-sans"
    >
      <button
        :if={!@panel_open}
        id="settings-gear"
        type="button"
        phx-click="toggle_panel"
        aria-label="Open caption settings"
        class="flex h-9 w-9 items-center justify-center rounded-full bg-gray-900/80 text-lg text-white shadow hover:bg-gray-700"
      >
        ⚙
      </button>
      <div
        :if={@panel_open}
        id="settings-panel"
        class="w-72 rounded-lg bg-gray-900 p-4 text-sm text-white shadow-xl"
      >
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-semibold">Caption appearance</h2>
          <button
            id="settings-close"
            type="button"
            phx-click="toggle_panel"
            aria-label="Close caption settings"
            class="rounded px-2 py-1 text-gray-300 hover:bg-gray-700 hover:text-white"
          >
            ✕
          </button>
        </div>
        <.form for={%{}} id="settings-form" phx-change="update_settings" class="space-y-3">
          <label class="block">
            <span class="mb-1 block text-gray-300">Font size ({@style.font_size}px)</span>
            <input
              type="range"
              name="font_size"
              min="10"
              max="120"
              value={@style.font_size}
              class="w-full"
            />
          </label>
          <div class="flex gap-3">
            <label class="block flex-1">
              <span class="mb-1 block text-gray-300">Text color</span>
              <input
                type="color"
                name="color"
                value={"#" <> @style.color_hex}
                class="h-8 w-full cursor-pointer rounded"
              />
            </label>
            <label class="block flex-1">
              <span class="mb-1 block text-gray-300">Background</span>
              <input
                type="color"
                name="bg"
                value={"#" <> @style.bg_hex}
                class="h-8 w-full cursor-pointer rounded"
              />
            </label>
          </div>
          <label class="block">
            <span class="mb-1 block text-gray-300">
              Background opacity ({@style.bg_opacity}%)
            </span>
            <input
              type="range"
              name="bg_opacity"
              min="0"
              max="100"
              value={@style.bg_opacity}
              class="w-full"
            />
          </label>
          <div class="flex gap-3">
            <label class="block flex-1">
              <span class="mb-1 block text-gray-300">Align</span>
              <select name="align" class="w-full rounded bg-gray-800 px-2 py-1">
                <option value="left" selected={@style.align == "left"}>Left</option>
                <option value="center" selected={@style.align == "center"}>Center</option>
                <option value="right" selected={@style.align == "right"}>Right</option>
              </select>
            </label>
            <label class="block flex-1">
              <span class="mb-1 block text-gray-300">Font</span>
              <select name="font" class="w-full rounded bg-gray-800 px-2 py-1">
                <option value="sans" selected={@style.font == "sans"}>Sans</option>
                <option value="serif" selected={@style.font == "serif"}>Serif</option>
                <option value="mono" selected={@style.font == "mono"}>Mono</option>
              </select>
            </label>
          </div>
          <label class="block">
            <span class="mb-1 block text-gray-300">Lines ({@style.lines})</span>
            <input
              type="range"
              name="lines"
              min="1"
              max="10"
              value={@style.lines}
              class="w-full"
            />
          </label>
          <label class="flex items-center gap-2">
            <input type="hidden" name="uppercase" value="false" />
            <input type="checkbox" name="uppercase" value="true" checked={@style.uppercase} />
            <span class="text-gray-300">Uppercase</span>
          </label>
        </.form>
        <div class="mt-4 border-t border-gray-700 pt-3">
          <span class="mb-1 block text-gray-300">OBS browser source URL</span>
          <div class="flex gap-2">
            <input
              id="overlay-url"
              type="text"
              readonly
              value={@current_url}
              onclick="this.select()"
              class="w-full rounded bg-gray-800 px-2 py-1 text-xs"
            />
            <button
              id="overlay-url-copy"
              type="button"
              phx-hook="CopyToClipboard"
              data-copy-target="overlay-url"
              class="shrink-0 rounded bg-gray-700 px-2 py-1 hover:bg-gray-600"
            >
              Copy
            </button>
          </div>
        </div>
      </div>
    </div>
    """
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
    font = parse_enum(params["font"], Map.keys(@font_stacks), "sans")

    uppercase? = parse_bool(params["uppercase"], stream_settings.text_uppercase)

    # The *_hex / bg_opacity / font / uppercase keys are the same validated
    # primitives echoed back for the settings form controls — not a second
    # parsing path.
    %{
      font_size: font_size,
      color: "rgb(#{r}, #{g}, #{b})",
      color_hex: to_hex(r, g, b),
      background: "rgba(#{bg_r}, #{bg_g}, #{bg_b}, #{bg_opacity / 100})",
      bg_hex: to_hex(bg_r, bg_g, bg_b),
      bg_opacity: bg_opacity,
      align: align,
      lines: lines,
      font: font,
      font_stack: @font_stacks[font],
      uppercase: uppercase?,
      text_transform: if(uppercase?, do: "uppercase", else: "none")
    }
  end

  defp to_hex(r, g, b) do
    Enum.map_join([r, g, b], fn component ->
      component |> Integer.to_string(16) |> String.pad_leading(2, "0")
    end)
    |> String.upcase()
  end

  defp caption_box_style(style) do
    [
      "background: #{style.background}",
      "color: #{style.color}",
      "font-family: #{style.font_stack}",
      "font-size: #{style.font_size}px",
      "text-align: #{style.align}",
      "text-transform: #{style.text_transform}",
      "border-radius: 4px",
      "padding: 0.4em 0.6em",
      "max-width: 100%"
    ]
    |> Enum.join("; ")
  end

  defp invalid_notice_style do
    [
      "background: rgba(0, 0, 0, 0.7)",
      "color: rgb(255, 255, 255)",
      "font-family: #{@font_stacks["sans"]}",
      "font-size: 20px",
      "line-height: 1.4",
      "border-radius: 4px",
      "padding: 0.6em 0.8em",
      "max-width: 100%",
      "text-align: center"
    ]
    |> Enum.join("; ")
  end

  # overflow: hidden clips at the padding box, so the clip container must be
  # a separate unpadded element sized to exactly N line-heights — clipping on
  # the padded caption box lets the tail of an extra line paint inside the
  # box's top padding.
  defp caption_clip_style(style) do
    [
      "line-height: 1.4",
      "max-height: calc(#{style.lines} * 1.4em)",
      "overflow: hidden",
      "display: flex",
      "flex-direction: column",
      "justify-content: flex-end",
      "overflow-wrap: break-word",
      "word-break: break-word"
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

  defp parse_bool(value, _default) when value in ["true", "1"], do: true
  defp parse_bool(value, _default) when value in ["false", "0"], do: false

  # Duplicate params (e.g. the hidden+checkbox pair for uppercase in the
  # settings form) can decode as a list — the last value wins, matching how
  # Plug resolves repeated keys.
  defp parse_bool([_ | _] = values, default), do: parse_bool(List.last(values), default)
  defp parse_bool(_value, default), do: default

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
