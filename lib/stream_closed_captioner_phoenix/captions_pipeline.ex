defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  require Logger

  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Settings
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings
  alias StreamClosedCaptionerPhoenixWeb.UserTracker
  alias Twitch.Extension.CaptionsPayload

  @type message_map :: %{
          optional(:final) => String.t(),
          optional(:interim) => String.t(),
          optional(:session) => String.t()
        }

  @spec pipeline_to(
          :twitch | :zoom | :default,
          StreamClosedCaptionerPhoenix.Accounts.User.t(),
          message_map()
        ) ::
          {:error, String.t()}
          | {:ok, CaptionsPayload.t()}
  def pipeline_to(:default, %User{} = user, message) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    payload =
      CaptionsPayload.new(message)
      |> maybe_censor_for(:interim, stream_settings)
      |> maybe_censor_for(:final, stream_settings)
      |> maybe_pirate_mode_for(:interim, stream_settings)
      |> maybe_pirate_mode_for(:final, stream_settings)

    {:ok, payload}
  end

  def pipeline_to(:twitch, %User{} = user, message) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    payload =
      CaptionsPayload.new(message)
      |> tap(fn _ ->
        UserTracker.update(self(), "active_channels", user.uid, %{
          last_publish: System.system_time(:second)
        })
      end)
      |> maybe_censor_for(:interim, stream_settings)
      |> maybe_censor_for(:final, stream_settings)
      |> Translations.maybe_translate(:final, user)
      |> maybe_pirate_mode_for(:interim, stream_settings)
      |> maybe_pirate_mode_for(:final, stream_settings)

    {:ok, payload}
  end

  def pipeline_to(:zoom, %User{} = user, message) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    params = %Zoom.Params{
      seq: get_in(message, ["zoom", "seq"]),
      lang: user.stream_settings.language
    }

    payload =
      CaptionsPayload.new(message)
      |> maybe_censor_for(:final, stream_settings)
      |> maybe_pirate_mode_for(:final, stream_settings)

    zoom_text = Map.get(payload, :final)
    url = get_in(message, ["zoom", "url"])

    case Zoom.send_captions_to(url, zoom_text, params) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, payload}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        Logger.debug("Request was rejected code: #{code} body: #{body}")
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.debug("Request was error")
        {:error, reason}
    end
  end

  defp maybe_censor_for(payload, key, %StreamSettings{} = stream_settings) do
    Map.put(
      payload,
      key,
      Profanity.maybe_censor(stream_settings, Map.get(payload, key))
    )
  end

  defp maybe_pirate_mode_for(payload, key, %StreamSettings{} = stream_settings) do
    if stream_settings.pirate_mode do
      {:ok, text} = TalkLikeAX.translate(Map.get(payload, key))

      Map.put(
        payload,
        key,
        text
      )
    else
      payload
    end
  end
end
