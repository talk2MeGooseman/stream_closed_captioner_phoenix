defmodule StreamClosedCaptionerPhoenix.AnnouncementAdmin do
  def index(_) do
    [
      display: nil,
      message: nil
    ]
  end

  def form_fields(_) do
    [
      display: nil,
      message: %{type: :richtext}
    ]
  end
end
