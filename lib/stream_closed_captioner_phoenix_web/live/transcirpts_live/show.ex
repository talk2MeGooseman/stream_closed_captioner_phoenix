defmodule StreamClosedCaptionerPhoenixWeb.TranscirptsLive.Show do
  use StreamClosedCaptionerPhoenixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: StreamClosedCaptionerPhoenixWeb.Endpoint.subscribe("transcript:1")

    _custom_styles = %{
      text: %{
        alignment: %{
          # left, middle, right
          horizontal: "full",
          # top, middle, bottom, lowerThird
          vertical: "full",
          # em
          padding: "0.25"
        }
      },
      shadow: %{
        color: "#000000",
        opacity: "100",
        blurRadius: "0",
        offsetX: "0.05",
        offsetY: "0.05"
      },
      background: %{
        color: "#000000",
        opacity: "100"
      }
    }

    transcript_styles =
      Enum.map(
        %{
          "color" => "#ffffff",
          "font-family" => "Cousine",
          "font-style" => "regular",
          "font-size" => "4" <> "em",
          "line-height" => "1.2" <> "em",
          "letter-spacing" => "0" <> "em",
          # uppercase or "capitalize" or "initial"
          "text-transform" => "uppercase"
        },
        fn {k, v} -> k <> ": " <> v <> ";" end
      )

    {:ok,
     socket
     |> assign(:transcript_styles, transcript_styles)
     |> assign(:interim, "")
     |> assign(:final_list, [])}
  end

  @impl true
  def handle_params(%{"id" => _id}, _, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_info(%{payload: %{"interim" => interim_text, "final" => ""}}, socket) do
    {:noreply, assign(socket, :interim, interim_text)}
  end

  def handle_info(%{payload: %{"interim" => _, "final" => final_text}}, socket) do
    new_final_list = socket.assigns.final_list ++ [final_text]

    {:noreply,
     socket
     |> assign(:interim, "")
     |> assign(:final_list, new_final_list)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Live Transcription"
end
