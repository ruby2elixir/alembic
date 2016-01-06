defmodule Alembic.Links do
  @moduledoc """
  > Where specified, a `links` member can be used to represent links. The value of each `links` member **MUST** be an
  > object (a "links object").
  >
  > -- <cite>
  >  [JSON API - Document Structure - Links](http://jsonapi.org/format/#document-links)
  > </cite>
  """

  alias Alembic.Link

  # Types

  @typedoc """
  Maps `String.t` name to `Alembic.Link.link`
  """
  @type t :: %{String.t => Link.link}
end
