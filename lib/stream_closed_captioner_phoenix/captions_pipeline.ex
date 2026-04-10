defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  require Logger
  use NewRelic.Tracer

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Profanity
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations
  alias StreamClosedCaptionerPhoenix.Settings
  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings
  alias Twitch.Extension.CaptionsPayload

  @type message_map :: %{optional(String.t()) => String.t()}

  @spec pipeline_to(
          :twitch | :zoom | :default,
          StreamClosedCaptionerPhoenix.Accounts.User.t(),
          message_map()
        ) ::
          {:error, String.t()}
          | {:ok, CaptionsPayload.t()}
  @trace :pipeline_to
  def pipeline_to(:default, %User{} = user, message) do
    with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
      payload =
        CaptionsPayload.new(message)
        |> apply_censoring(stream_settings)
        |> apply_pirate_mode(stream_settings)

      {:ok, payload}
    else
      {:error, _} -> {:error, "Stream settings not found"}
    end
  end

  @trace :pipeline_to
  def pipeline_to(:twitch, %User{} = user, message) do
    with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
      payload =
        CaptionsPayload.new(message)
        |> apply_censoring(stream_settings)
        |> Translations.maybe_translate(:final, user)
        |> apply_pirate_mode(stream_settings)

      {:ok, payload}
    else
      {:error, _} -> {:error, "Stream settings not found"}
    end
  end

  @trace :pipeline_to
  def pipeline_to(:zoom, %User{} = user, message) do
    with {:ok, stream_settings} <- Settings.get_stream_settings_by_user_id(user.id) do
      params = %Zoom.Params{
        seq: get_in(message, ["zoom", "seq"]),
        lang: stream_settings.language
      }

      payload =
        CaptionsPayload.new(message)
        |> apply_users_blocklist_for(:final, stream_settings)
        |> maybe_additional_censoring_for(:final, stream_settings)
        |> maybe_pirate_mode_for(:final, stream_settings)

      zoom_text = Map.get(payload, :final)

      with {:ok, url} <- validate_zoom_url(get_in(message, ["zoom", "url"])) do
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
    else
      {:error, _} -> {:error, "Stream settings not found"}
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

  defp maybe_pirate_mode_for(payload, key, %StreamSettings{pirate_mode: true}) do
    case TalkLikeAX.translate(Map.get(payload, key)) do
      {:ok, text} ->
        Map.put(payload, key, text)

      {:error, reason} ->
        Logger.warning("Pirate mode translation failed: #{inspect(reason)}")
        payload
    end
  end

  defp maybe_pirate_mode_for(payload, _key, _stream_settings), do: payload

  defp validate_zoom_url(url) when is_binary(url) do
    uri = URI.parse(url)

    cond do
      uri.scheme != "https" ->
        Logger.warning("Rejected non-HTTPS Zoom URL: #{inspect(uri.scheme)}")
        {:error, :invalid_zoom_url}

      not String.ends_with?(uri.host || "", ".zoom.us") ->
        Logger.warning("Rejected non-Zoom host: #{inspect(uri.host)}")
        {:error, :invalid_zoom_url}

      true ->
        {:ok, url}
    end
  end

  defp validate_zoom_url(_), do: {:error, :invalid_zoom_url}
end
