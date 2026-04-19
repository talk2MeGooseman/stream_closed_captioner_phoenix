defmodule StreamClosedCaptionerPhoenixWeb.HTTPSignature do
  @behaviour Plug

  @twitch_message_id "twitch-eventsub-message-id"
  @twitch_message_timestamp "twitch-eventsub-message-timestamp"
  @twitch_message_signature "twitch-eventsub-message-signature"
  @twitch_message_type "twitch-eventsub-message-type"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, body} <- raw_body(conn),
         true <- verify(conn, body),
         [type] <- Plug.Conn.get_req_header(conn, @twitch_message_type) do
      conn
      |> Plug.Conn.assign(:twitch_event_type, type)
    else
      _ ->
        conn
        |> Plug.Conn.resp(400, "")
        |> Plug.Conn.halt()
    end
  end

  @spec verify(Plug.Conn.t(), binary) :: boolean
  def verify(conn, body) do
    with {:ok, message} <- get_hmac_message(conn, body),
         [signature] <- Plug.Conn.get_req_header(conn, @twitch_message_signature) do
      hmac = "sha256=" <> get_hmac(message)
      Plug.Crypto.secure_compare(signature, hmac)
    else
      _ -> false
    end
  end

  @doc """
  Build the message used to get the HMAC.
  """
  def get_hmac_message(conn, body) do
    with [message_id] <- Plug.Conn.get_req_header(conn, @twitch_message_id),
         [message_timestamp] <- Plug.Conn.get_req_header(conn, @twitch_message_timestamp) do
      {:ok, message_id <> message_timestamp <> body}
    else
      _ -> {:error, :missing_headers}
    end
  end

  def get_hmac(message),
    do:
      :crypto.mac(:hmac, :sha256, Twitch.HttpHelpers.eventsub_secret(), message)
      |> Base.encode16(case: :lower)

  defp raw_body(conn) do
    case conn do
      %Plug.Conn{assigns: %{raw_body: raw_body}} ->
        # We cached as iodata, so we need to transform here.
        {:ok, IO.iodata_to_binary(raw_body)}

      _ ->
        # If we forget to use the plug or there is no content-type on the request
        {:error, "raw body is not present or request content-type is missing"}
    end
  end
end
