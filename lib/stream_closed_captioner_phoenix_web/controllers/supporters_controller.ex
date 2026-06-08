defmodule StreamClosedCaptionerPhoenixWeb.SupportersController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenixWeb.Layouts

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    {:ok, %{"data" => data}} = GoosemanApp.fetch_supporters()

    conn
    # Bare-tuple form so it replaces the `:browser` pipeline's root layout,
    # which is set the same way. A `[html: ...]` form is stored under a
    # separate key and shadowed by the pipeline's catch-all, leaving the old
    # nav/footer chrome in place. See ShowcaseController for the full why.
    |> put_root_layout({Layouts, :scc_root})
    |> put_layout(html: {Layouts, :scc})
    |> assign(:scc_active, "supporters")
    |> assign(:page_title, "Supporters · Help keep the captions flowing")
    |> render("index.html", data: data)
  end
end
