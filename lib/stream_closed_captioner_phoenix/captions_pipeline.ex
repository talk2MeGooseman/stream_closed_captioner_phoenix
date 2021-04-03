defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.{Profanity, Translations}
  alias Twitch.Extension.CaptionsPayload

  @type message_map :: %{
          required(:final) => String.t(),
          required(:interim) => String.t(),
          required(:session) => String.t()
        }

  @spec pipeline_to(
          :twitch | :zoom,
          StreamClosedCaptionerPhoenix.Accounts.User.t(),
          message_map()
        ) ::
          {:error, String.t()}
          | {:ok, CaptionsPayload.t()}

  def pipeline_to(:zoom, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    params = %Zoom.Params{
      seq: Map.get(message, :seq),
      lang: user.stream_settings.language
    }

    url = Map.get(message, :url)
    text = maybe_censor_for(message, :final, user) |> Map.get(:final)
    Zoom.send_captions_to(url, text, params)
  end

  def pipeline_to(:twitch, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    CaptionsPayload.new(message)
    |> maybe_censor_for(:interim, user)
    |> maybe_censor_for(:final, user)
    |> Translations.maybe_translate(:interim, user)
    |> send_to(:twitch, user)
  end

  defp send_to(payload, :twitch, user) do
    case Twitch.send_pubsub_message(payload, user.uid) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        IO.puts("Message sent successfully")
        {:ok, payload}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        IO.puts("Request was rejected")
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp maybe_censor_for(payload, key, %User{} = user) do
    Map.put(
      payload,
      key,
      Profanity.maybe_censor(user.stream_settings, Map.get(payload, key))
    )
  end
end
