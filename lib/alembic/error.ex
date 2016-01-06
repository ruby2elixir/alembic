defmodule Alembic.Error do
  @moduledoc """
  [Error objects](http://jsonapi.org/format/#error-objects) provide additional information about problems encountered
  while performing an operation. Error objects **MUST** be returned as an array keyed by `errors` in the top level of a
  JSON API document.
  """

  alias Alembic.Links
  alias Alembic.Meta
  alias Alembic.Source

  defstruct code: nil,
            detail: nil,
            id: nil,
            links: nil,
            meta: nil,
            source: nil,
            status: nil,
            title: nil

  # Types

  @typedoc """
  Additional information about problems encountered while performing an operation.

  An error object **MAY** have the following members:

  * `code` - an application-specific error code.
  * `detail` - a human-readable explanation specific to this occurrence of the problem.
  * `id` - a unique identifier for this particular occurrence of the problem.
  * `links` - contains the following members:
      * `"about"` - an `Alembic.Link.link` leading to further details about this particular occurrence of the problem.
  * `meta` - non-standard meta-information about the error.
  * `source` - contains references to the source of the error, optionally including any of the following members:
  * `status` - the HTTP status code applicable to this problem.
  * `title` - a short, human-readable summary of the problem that **SHOULD NOT** change from occurrence to occurrence of
    the problem, except for purposes of localization.
  """
  @type t :: %__MODULE__{
               code: String.t,
               detail: String.t,
               id: String.t,
               links: Links.t,
               meta: Meta.t,
               source: Source.t,
               status: String.t,
               title: String.t
             }
end
