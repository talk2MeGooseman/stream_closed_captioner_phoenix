defmodule BodyReader do
  def cache_raw_body(conn, opts) do
    with {:ok, body, conn} <- Plug.Conn.read_body(conn, opts) do
      conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])

      {:ok, body, conn}
    end
  end
end
