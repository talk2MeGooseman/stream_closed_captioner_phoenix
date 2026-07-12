defmodule StreamClosedCaptionerPhoenixWeb.CostreamLiveTest do
  # async: false because FunWithFlags keeps flag state in a shared in-memory cache.
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.Costream

  setup :register_and_log_in_user

  setup %{user: user} do
    FunWithFlags.enable(Costream.feature_flag())
    # DB toggle rows roll back with the sandbox; flush only the shared cache.
    on_exit(fn -> FunWithFlags.Store.Cache.flush() end)
    %{user: StreamClosedCaptionerPhoenix.Repo.preload(user, :stream_settings)}
  end

  test "shows a notice when the feature flag is off", %{conn: conn, user: user} do
    FunWithFlags.disable(Costream.feature_flag(), for_actor: user)
    FunWithFlags.disable(Costream.feature_flag())

    {:ok, _view, html} = live(conn, ~p"/users/costream")
    assert html =~ "aren&#39;t enabled for your account yet"
  end

  test "creates a guest link", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, ~p"/users/costream")

    view
    |> form("form[phx-submit=create_guest]", %{"name" => "Alice"})
    |> render_submit()

    assert [%{name: "Alice"}] = Costream.list_active_guests(user)
    assert render(view) =~ "Alice"
    assert render(view) =~ "/costream/"
  end

  test "enforces the guest cap", %{conn: conn, user: user} do
    for i <- 1..Costream.max_active_guests() do
      {:ok, _} = Costream.create_guest(user, %{name: "Guest #{i}"})
    end

    {:ok, view, _html} = live(conn, ~p"/users/costream")

    view
    |> form("form[phx-submit=create_guest]", %{"name" => "Extra"})
    |> render_submit()

    assert length(Costream.list_active_guests(user)) == Costream.max_active_guests()

    rendered = render(view)
    refute rendered =~ "Extra"
    # The template renders the :error flash itself (the scc layout doesn't).
    assert rendered =~ "at most #{Costream.max_active_guests()} active guests"
  end

  test "mutes and unmutes a guest", %{conn: conn, user: user} do
    {:ok, guest} = Costream.create_guest(user, %{name: "Alice"})

    {:ok, view, _html} = live(conn, ~p"/users/costream")

    view
    |> element("#guest-#{guest.id} button[phx-click=toggle_mute]")
    |> render_click()

    assert {:ok, %{muted: true}} = Costream.get_guest_for(user, guest.id)
    assert render(view) =~ "Unmute"
  end

  test "revokes a guest", %{conn: conn, user: user} do
    {:ok, guest} = Costream.create_guest(user, %{name: "Alice"})

    {:ok, view, _html} = live(conn, ~p"/users/costream")

    view
    |> element("#guest-#{guest.id} button[phx-click=revoke]")
    |> render_click()

    assert Costream.list_active_guests(user) == []
    refute has_element?(view, "#guest-#{guest.id}")
  end

  test "toggles the kill switch", %{conn: conn, user: user} do
    {:ok, view, html} = live(conn, ~p"/users/costream")
    assert html =~ "Guest captions ON"

    view
    |> element("button[phx-click=toggle_kill_switch]")
    |> render_click()

    assert render(view) =~ "Guest captions OFF"

    {:ok, settings} =
      StreamClosedCaptionerPhoenix.Settings.get_stream_settings_by_user_id(user.id)

    refute settings.costream_enabled
  end

  test "shows live guest caption text from the monitor topic", %{conn: conn, user: user} do
    {:ok, guest} = Costream.create_guest(user, %{name: "Alice"})

    {:ok, view, _html} = live(conn, ~p"/users/costream")

    Phoenix.PubSub.broadcast(
      StreamClosedCaptionerPhoenix.PubSub,
      Costream.monitor_topic(user.id),
      {:costream_caption,
       %{guest_id: guest.id, name: "Alice", interim: "typing", final: "hello there"}}
    )

    rendered = render(view)
    assert rendered =~ "hello there"
    assert rendered =~ "typing"
  end

  test "marks guests connected on join broadcasts", %{conn: conn, user: user} do
    {:ok, guest} = Costream.create_guest(user, %{name: "Alice"})

    {:ok, view, html} = live(conn, ~p"/users/costream")
    assert html =~ "Offline"

    Phoenix.PubSub.broadcast(
      StreamClosedCaptionerPhoenix.PubSub,
      Costream.monitor_topic(user.id),
      {:costream_guest_joined, %{guest_id: guest.id, name: "Alice"}}
    )

    assert render(view) =~ "Connected"

    Phoenix.PubSub.broadcast(
      StreamClosedCaptionerPhoenix.PubSub,
      Costream.monitor_topic(user.id),
      {:costream_guest_left, %{guest_id: guest.id}}
    )

    assert render(view) =~ "Offline"
  end
end
