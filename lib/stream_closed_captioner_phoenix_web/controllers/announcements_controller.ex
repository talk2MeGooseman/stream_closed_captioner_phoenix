defmodule StreamClosedCaptionerPhoenixWeb.AnnouncementsController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  alias StreamClosedCaptionerPhoenix.Announcements

  def index(conn, _params) do
    pages = Announcements.list_announcement_pages()
    render(conn, "index.html", pages: pages)
  end
end
