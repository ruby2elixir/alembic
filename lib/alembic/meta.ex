defmodule Alembic.Meta do
  @moduledoc """
  > Where specified, a `meta` member can be used to include non-standard meta-information. The value of each `meta`
  > member **MUST** be an object (a "meta object").
  >
  > -- <cite>
  >  [JSON API - Document Structure - Meta Information](http://jsonapi.org/format/#document-meta)
  > </cite>
  """

  # Types

  @type t :: Alembic.json_object
end
