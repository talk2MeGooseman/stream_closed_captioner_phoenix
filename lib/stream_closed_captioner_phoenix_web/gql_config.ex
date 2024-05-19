defmodule StreamClosedCaptionerPhoenixWeb.GqlConfig do
  def configuration do
    [
      schema: StreamClosedCaptionerPhoenixWeb.Schema,
      pipeline: {__MODULE__, :absinthe_pipeline},
      analyze_complexity: true,
      max_complexity: 50
    ]
  end

  def absinthe_pipeline(config, options) do
    options = Absinthe.Pipeline.options(options)

    config
    |> Absinthe.Plug.default_pipeline(options)
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Complexity.Result,
      {AbsintheSecurity.Phase.IntrospectionCheck, options}
    )
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Result,
      {AbsintheSecurity.Phase.FieldSuggestionsCheck, options}
    )
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Complexity.Result,
      {AbsintheSecurity.Phase.MaxAliasesCheck, options}
    )
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Complexity.Result,
      {AbsintheSecurity.Phase.MaxDepthCheck, options}
    )
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Complexity.Result,
      {AbsintheSecurity.Phase.MaxDirectivesCheck, options}
    )
  end
end
