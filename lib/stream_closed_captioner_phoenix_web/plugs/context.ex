defmodule StreamClosedCaptionerPhoenixWeb.Context do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context =
      %{}
      |> build_user_context(conn)
      |> build_token_context(conn)

    put_private(conn, :absinthe, %{context: context})
  end

  defp build_user_context(context, conn) do
    with ["" <> token] <- get_req_header(conn, "authorization"),
         {:ok, user, _claims} <- StreamClosedCaptionerPhoenix.Guardian.resource_from_token(token) do
      Map.merge(context, %{current_user: user})
    else
      _ -> context
    end
  end

  defp build_token_context(context, conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, decoded_token} <- Twitch.Jwt.verify_and_validate(token) do
      Map.merge(context, %{decoded_token: decoded_token})
    else
      _ -> context
    end
  end
end
