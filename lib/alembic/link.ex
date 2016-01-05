defmodule Alembic.Link do
  @moduledoc """
  A [link object](http://jsonapi.org/format/#document-links) represents a URL and metadata about it.
  """

  alias Alembic.Meta

  # Constants

  @human_type "a link object"

  # Struct

  defstruct href: nil,
            meta: nil

  # Types

  @typedoc """
  An [link object](http://jsonapi.org/format/#document-links) which can contain the following members:
  * `href` - the link's URL.
  * `meta` - contains non-standard meta-information about the link.
  """
  @type t :: %__MODULE__{
               href: String.t | nil,
               meta: Meta.t | nil
             }

  @typedoc """
  * a `String.t` containing the link's URL.
  * a `t`
  """
  @type link :: String.t | t
end
