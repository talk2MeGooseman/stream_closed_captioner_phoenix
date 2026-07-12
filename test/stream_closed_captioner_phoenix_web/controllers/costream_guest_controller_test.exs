defmodule StreamClosedCaptionerPhoenixWeb.CostreamGuestControllerTest do
  # async: false because FunWithFlags keeps flag state in a shared in-memory cache.
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.Costream

  setup do
    # DB toggle rows roll back with the sandbox; flush only the shared cache.
    on_exit(fn -> FunWithFlags.Store.Cache.flush() end)
    %{host: insert(:user)}
  end

  test "renders the guest dashboard for a valid link", %{conn: conn, host: host} do
    FunWithFlags.enable(Costream.feature_flag())
    guest = insert(:costream_guest, user: host, name: "Alice")

    conn = get(conn, ~p"/costream/#{Costream.guest_token(guest)}")

    response = html_response(conn, 200)
    assert response =~ "You're captioning as Alice"
    assert response =~ "data-controller=\"costream\""
    assert response =~ "data-costream-host-id-value=\"#{host.id}\""
  end

  test "renders the invalid page for a revoked link", %{conn: conn, host: host} do
    FunWithFlags.enable(Costream.feature_flag())
    guest = insert(:costream_guest, user: host)
    token = Costream.guest_token(guest)
    {:ok, _} = Costream.revoke_guest(guest)

    conn = get(conn, ~p"/costream/#{token}")

    assert html_response(conn, 404) =~ "This co-stream link isn't valid"
  end

  test "renders the invalid page when the feature flag is off", %{conn: conn, host: host} do
    guest = insert(:costream_guest, user: host)

    conn = get(conn, ~p"/costream/#{Costream.guest_token(guest)}")

    assert html_response(conn, 404) =~ "This co-stream link isn't valid"
  end

  test "renders the invalid page for garbage tokens", %{conn: conn} do
    conn = get(conn, ~p"/costream/garbage")

    assert html_response(conn, 404)
  end
end
