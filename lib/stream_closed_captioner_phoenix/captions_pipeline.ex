defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  require Logger

  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations
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
      |> apply_censoring(stream_settings)
      |> apply_pirate_mode(stream_settings)

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
      |> apply_censoring(stream_settings)
      |> Translations.maybe_translate(:final, user)
      |> apply_pirate_mode(stream_settings)

    {:ok, payload}
  end

  def pipeline_to(:zoom, %User{} = user, message) do
    {:ok, stream_settings} = Settings.get_stream_settings_by_user_id(user.id)

    params = %Zoom.Params{
      seq: get_in(message, ["zoom", "seq"]),
      lang: stream_settings.language
    }

    payload =
      CaptionsPayload.new(message)
      |> maybe_additional_censoring_for(:final, stream_settings)
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

  defp apply_censoring(payload, %StreamSettings{} = stream_settings) do
    payload
    |> apply_users_blocklist_for(:interim, stream_settings)
    |> apply_users_blocklist_for(:final, stream_settings)
    |> maybe_additional_censoring_for(:interim, stream_settings)
    |> maybe_additional_censoring_for(:final, stream_settings)
  end

  @spec apply_users_blocklist_for(
          CaptionsPayload.t(),
          :interim | :final,
          StreamSettings.t()
        ) :: CaptionsPayload.t()
  defp apply_users_blocklist_for(payload, key, stream_settings) do
    update_in(
      payload,
      [Access.key(key)],
      fn text -> Profanity.censor_from_blocklist(stream_settings, text) end
    )
  end

  @spec maybe_additional_censoring_for(
          CaptionsPayload.t(),
          :interim | :final,
          StreamSettings.t()
        ) :: CaptionsPayload.t()
  defp maybe_additional_censoring_for(payload, key, stream_settings) do
    update_in(
      payload,
      [Access.key(key)],
      fn text -> Profanity.maybe_additional_censoring(stream_settings, text) end
    )
  end

  @spec apply_pirate_mode(
          CaptionsPayload.t(),
          StreamSettings.t()
        ) :: CaptionsPayload.t()
  defp apply_pirate_mode(payload, %StreamSettings{} = stream_settings) do
    payload
    |> maybe_pirate_mode_for(:interim, stream_settings)
    |> maybe_pirate_mode_for(:final, stream_settings)
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
