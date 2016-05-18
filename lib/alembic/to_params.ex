defmodule Alembic.ToParams do
  @moduledoc """
  The `Alembic.ToParams` behaviour converts a data structure in the `Alembic` namespace to
  the params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).
  """

  # Types

  @typedoc """
  Params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).
  """
  @type params :: list | map | nil

  @typedoc """
  A nest map with the outer layer keyed by the `Alembic.Resource.type`, then the next layer keyed by the
  `Alembic.Resource.id` with the values being the full `Alembic.Resource.t`
  """
  @type resource_by_id_by_type :: %{Resource.type => %{Resource.id => Resource.t}}

  # Callbacks

  @doc """
  ## Parameters

  * `any` - an `Alembic.Document.t` hierarchy data structure
  * `resources_by_id_by_type` - A nest map with the outer layer keyed by the `Alembic.Resource.type`,
    then the next layer keyed by the `Alembic.Resource.id` with the values being the full
    `Alembic.Resource.t` from `Alembic.Document.t` `included`.

  ## Returns

  * `nil` if an empty singleton
  * `%{}` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[%{}]` - if a non-empty collection
  """
  @callback to_params(any, resource_by_id_by_type) :: params
end
