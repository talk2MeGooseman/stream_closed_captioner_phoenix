defmodule StreamClosedCaptionerPhoenixWeb.AnnouncementsController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  def index(conn, _params) do
    pages =
      case Notion.Database.query_database("8f9f6076e708455fbb263b3ba9ca48db") do
        {:ok, response} -> get_in(response, ["results"])
        _ -> []
      end

    render(conn, "index.html", pages: pages)
  end
end
