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
         true <- verify(conn, body) do
      [type] = Plug.Conn.get_req_header(conn, @twitch_message_type)

      conn
      |> Plug.Conn.assign(:twitch_event_type, type)
    else
      {:error, _} ->
        conn
        |> Plug.Conn.put_status(400)
        |> Plug.Conn.halt()
    end
  end

  @spec verify(Plug.Conn.t(), binary) :: boolean
  def verify(conn, body) do
    message = getHmacMessage(conn, body)
    hmac = "sha256=" <> getHmac(message)
    [signature] = Plug.Conn.get_req_header(conn, @twitch_message_signature)

    Plug.Crypto.secure_compare(signature, hmac)
  end

  @doc """
  Build the message used to get the HMAC.
  """
  def getHmacMessage(conn, body) do
    [message_id] = Plug.Conn.get_req_header(conn, @twitch_message_id)
    [message_timestamp] = Plug.Conn.get_req_header(conn, @twitch_message_timestamp)

    message_id <> message_timestamp <> body
  end

  def getHmac(message),
    do:
      :crypto.mac(:hmac, :sha256, Twitch.HttpHelpers.client_secret(), message)
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
