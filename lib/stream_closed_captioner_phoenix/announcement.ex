defmodule StreamClosedCaptionerPhoenix.Announcement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "announcements" do
    field :display, :boolean
    field :message, :string
  end

  @doc false
  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:message, :display])
  end
end
