defmodule StreamClosedCaptionerPhoenixWeb.Layouts do
  @moduledoc false
  use StreamClosedCaptionerPhoenixWeb, :html

  embed_templates "layouts/email.html", suffix: "_html"
  embed_templates "layouts/email.text", suffix: "_text"
  embed_templates "layouts/_*"
  embed_templates "layouts/a*"
  embed_templates "layouts/l*"
  embed_templates "layouts/r*"
  embed_templates "layouts/s*"
  embed_templates "layouts/t*"
end
