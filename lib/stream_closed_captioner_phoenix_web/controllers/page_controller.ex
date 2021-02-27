defmodule StreamClosedCaptionerPhoenixWeb.PageController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  def dynamic(conn, _params) do
    render_dynamic(conn)
  end
end
