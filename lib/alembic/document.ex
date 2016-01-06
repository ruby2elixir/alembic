defmodule Alembic.Document do
  @moduledoc """
  JSON API refers to the top-level JSON structure as a [document](http://jsonapi.org/format/#document-structure).
  """

  alias Alembic.Error

  defstruct errors: nil

  # Types

  @typedoc """
  A JSON API [Document](http://jsonapi.org/format/#document-structure).

  ## Errors

  When an error occurs, only `errors` are returned in the document.
  """
  @type t :: %__MODULE__{
               errors: [Error.t],
             }
end
