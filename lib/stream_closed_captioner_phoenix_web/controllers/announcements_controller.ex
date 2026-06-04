defmodule StreamClosedCaptionerPhoenixWeb.AnnouncementsController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Announcements
  alias StreamClosedCaptionerPhoenixWeb.Layouts

  def index(conn, _params) do
    pages = Announcements.list_announcement_pages()

    conn
    # Bare-tuple form so it replaces the `:browser` pipeline's root layout,
    # which is set the same way. A `[html: ...]` form is stored under a
    # separate key and shadowed by the pipeline's catch-all, leaving the old
    # nav/footer chrome in place. See ShowcaseController for the full why.
    |> put_root_layout({Layouts, :scc_root})
    |> put_layout(html: {Layouts, :scc})
    |> assign(:scc_active, "announcements")
    |> assign(:page_title, "Announcements · What's new in Stream CC")
    |> render("index.html", pages: pages)
  end
end
