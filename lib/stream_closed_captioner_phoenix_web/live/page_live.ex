defmodule StreamClosedCaptionerPhoenixWeb.PageLive do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  @base_features [
    %{
      icon: "twitch",
      title: "Captions for Twitch",
      desc: "Run it as an overlay or a channel panel extension — and it works on mobile, too."
    },
    %{
      icon: "zoom",
      title: "Captions for Zoom",
      desc: "Drop in your meeting URL and go. No installs for the people on your call."
    },
    %{
      icon: "settings",
      title: "Streamer & viewer settings",
      desc: "Language, size and position — set your defaults, and let viewers tune their own."
    }
  ]

  @enhanced_features [
    %{
      icon: "translate",
      title: "Translation with Bits",
      desc: "Viewers unlock captions translated into your selected language by spending Bits."
    },
    %{
      icon: "vod",
      title: "Captions in your VODs",
      desc: "Burn captions into recordings through the OBS WebSocket for OBS Studio."
    }
  ]

  @steps [
    %{
      title: "Install the extension",
      desc: "Activate Stream CC as an overlay or panel on your Twitch channel.",
      img: "install-extension.png",
      alt: "The Stream Closed Captioner Twitch extension installation page"
    },
    %{
      title: "Sign up for an account",
      desc: "Use your Twitch login — or an e-mail for Zoom-only captions.",
      img: "register.png",
      alt: "The Stream Closed Captioner registration page"
    },
    %{
      title: "Get your settings right",
      desc: "Pick your native language, add a Zoom URL, set size and position.",
      img: "settings.png",
      alt: "The Stream Closed Captioner caption settings page"
    },
    %{
      title: "Start Closed Captions",
      desc: "One button on your dashboard and you're captioning live.",
      img: "captions-start.png",
      alt: "The Stream Closed Captioner dashboard, focused on the start captions button"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Stream CC — Closed captions for your stream")
     |> assign(:base_features, @base_features)
     |> assign(:enhanced_features, @enhanced_features)
     |> assign(:steps, @steps)}
  end

  @doc """
  Simple geometric feature icon (stroke inherits `currentColor` from the parent).
  """
  attr :name, :string, required: true

  def feature_icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "twitch" -> %>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <rect x="3" y="5" width="18" height="14" rx="3" />
          <path d="M11 10.2a2.3 2.3 0 0 0-3.6 1.9 2.3 2.3 0 0 0 3.6 1.9M17.5 10.2a2.3 2.3 0 0 0-3.6 1.9 2.3 2.3 0 0 0 3.6 1.9" />
        </svg>
      <% "zoom" -> %>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <rect x="3" y="6" width="12" height="12" rx="3" />
          <path d="M15 10.5 21 7v10l-6-3.5" />
        </svg>
      <% "settings" -> %>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M4 8h10M18 8h2M4 16h2M10 16h10" />
          <circle cx="16" cy="8" r="2.4" />
          <circle cx="8" cy="16" r="2.4" />
        </svg>
      <% "translate" -> %>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M4 8h8M8 5v3M6 8c0 3.5 2 5.5 4 6.5M10.5 8c0 3-2 5-4.5 6.5" />
          <path d="M14 19l3-7 3 7M15.2 16.6h3.6" />
        </svg>
      <% "vod" -> %>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M20 12a8 8 0 1 1-2.4-5.7" />
          <path d="M20 4v3.5h-3.5" />
          <path d="M10.5 9.3v5.4l4.5-2.7-4.5-2.7Z" />
        </svg>
      <% _ -> %>
    <% end %>
    """
  end
end
