defmodule StreamClosedCaptionerPhoenixWeb.TermsController do
  use StreamClosedCaptionerPhoenixWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
