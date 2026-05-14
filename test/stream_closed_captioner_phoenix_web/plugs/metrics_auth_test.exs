defmodule StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuthTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  alias StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth

  setup do
    Application.put_env(:stream_closed_captioner_phoenix, :metrics_auth_token, "supersecret")
    on_exit(fn ->
      Application.delete_env(:stream_closed_captioner_phoenix, :metrics_auth_token)
    end)
    :ok
  end

  test "returns 401 when Authorization header is missing", %{conn: conn} do
    conn = MetricsAuth.call(conn, [])
    assert conn.status == 401
    assert conn.halted
  end

  test "returns 401 when token is wrong", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer wrong")
      |> MetricsAuth.call([])

    assert conn.status == 401
    assert conn.halted
  end

  test "passes through when token is correct", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_req_header("authorization", "Bearer supersecret")
      |> MetricsAuth.call([])

    refute conn.halted
  end
end
