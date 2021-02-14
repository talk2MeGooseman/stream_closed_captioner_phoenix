defmodule StreamClosedCaptionerPhoenixWeb.Context do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    case build_context(conn) do
      {:ok, context} ->
        put_private(conn, :absinthe, %{context: context})

      _ ->
        conn
    end
  end

  defp build_context(conn) do
    with ["" <> token] <- get_req_header(conn, "authorization"),
         {:ok, user, _claims} <- StreamClosedCaptionerPhoenix.Guardian.resource_from_token(token) do
      {:ok, %{current_user: user}}
    end
  end
end