defmodule Alembic.Source do
  @moduledoc """
  The `source` of an error.
  """

  alias Alembic

  defstruct [:parameter, :pointer]

  # Types

  @typedoc """
  An object containing references to the source of the [error](http://jsonapi.org/format/#error-objects), optionally
  including any of the following members:

  * `pointer` - JSON Pointer ([RFC6901](https://tools.ietf.org/html/rfc6901)) to the associated entity in the request
    document (e.g. `"/data"` for a primary data object, or `"/data/attributes/title"` for a specific attribute).
  * `parameter` - URL query parameter caused the error.
  """
  @type t :: %__MODULE__{
               parameter: String.t,
               pointer: Api.json_pointer
             }
end
