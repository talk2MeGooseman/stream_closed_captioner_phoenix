defmodule StreamClosedCaptionerPhoenixWeb.SupportersController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    {:ok, %{"data" => data}} = GoosemanApp.fetch_supporters()

    render(conn, "index.html", data: data)
  end
end
