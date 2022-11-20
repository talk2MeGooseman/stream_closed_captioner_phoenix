defmodule StreamClosedCaptionerPhoenixWeb.Schema.Middleware.AuthorizedIntrospection do
  @moduledoc """
  Disable or restrict schema introspection to authorized requests
  """
  @behaviour Absinthe.Plugin

  @impl Absinthe.Plugin
  def before_resolution(exec) do
    if Enum.find(exec.result.emitter.selections, fn %{name: field_name} ->
         field_name == "__schema" && Mix.env() != :dev
       end) do
      %{
        exec
        | validation_errors: [
            %Absinthe.Phase.Error{message: "Unauthorized", phase: __MODULE__}
          ]
      }
    else
      exec
    end
  end

  @impl Absinthe.Plugin
  def after_resolution(exec), do: exec

  @impl Absinthe.Plugin
  def pipeline(pipeline, _exec), do: pipeline
end
