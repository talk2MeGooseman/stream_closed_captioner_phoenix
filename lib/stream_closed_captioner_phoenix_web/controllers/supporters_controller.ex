defmodule StreamClosedCaptionerPhoenixWeb.SupportersController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  def index(conn, _params) do
    {:ok, %{"data" => data}} = StreamClosedCaptionerPhoenix.GoosemanApp.fetch_supporters()
    render(conn, "index.html", data: data)
  end
end
