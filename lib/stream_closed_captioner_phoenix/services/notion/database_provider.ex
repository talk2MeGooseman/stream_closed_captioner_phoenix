defmodule Notion.DatabaseProvider do
  @moduledoc """
  Behaviour for Notion database operations.

  Allows real and mock implementations to be swapped via application config,
  following the same provider pattern used throughout this project.
  """

  @callback query_database(database_id :: String.t(), body :: map()) ::
              {:ok, map()} | {:error, term()}
end
