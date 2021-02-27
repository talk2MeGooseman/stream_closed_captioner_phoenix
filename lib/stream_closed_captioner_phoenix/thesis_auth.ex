defmodule StreamClosedCaptionerPhoenix.ThesisAuth do
  @moduledoc """
  Contains functions for handling Thesis authorization.
  """

  @behaviour Thesis.Auth

  def page_is_editable?(_conn) do
    # Editable by the world
    true

    # Or use your own auth strategy. Learn more:
    # https://github.com/infinitered/thesis-phoenix#authorization
  end
end
