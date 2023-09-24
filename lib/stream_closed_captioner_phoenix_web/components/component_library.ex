defmodule StreamClosedCaptionerPhoenixWeb.ComponentLibrary do
  defmacro __using__(_) do
    quote do
      import StreamClosedCaptionerPhoenixWeb.ComponentLibrary
      # Import additional component modules below
      import StreamClosedCaptionerPhoenixWeb.Components.Dropdowns
      import StreamClosedCaptionerPhoenixWeb.Components.Cards
      import StreamClosedCaptionerPhoenixWeb.Components.Tables
    end
  end

  @moduledoc """
  This module is added and used in StreamClosedCaptionerPhoenixWeb. The idea is
  different component modules can be added and imported in the macro section above.
  """
  use Phoenix.Component
end
