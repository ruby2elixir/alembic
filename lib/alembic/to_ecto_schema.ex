defmodule Alembic.ToEctoSchema do
  @moduledoc """
  The `Alembic.ToEctoSchema` behaviour converts a struct in the `Alembic` namespace to
  an `Ecto.Schema.t` struct.
  """

  alias Alembic.Resource
  alias Alembic.ToParams

  # Types

  @typedoc """
  * `nil` if an empty singleton
  * `struct` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[struct]` - if a non-empty collection
  """
  @type ecto_schema :: nil | struct | [] | [struct, ...]

  @typedoc """
  A module that defines `__struct__/0` and `__schema__(:fields)` as happens when `use Ecto.Schema` is run in a module.
  """
  @type ecto_schema_module :: atom

  @typedoc """
  Maps JSON API `Alembic.Resource.type` to `ecto_schema_module` for casting that
  `Alembic.Resource.type`.
  """
  @type ecto_schema_module_by_type :: %{Resource.type => ecto_schema_module}

  @doc """
  ## Parameters

  * `struct` - an `Alembic.Document.t` hierarchy struct
  * `attributes_by_id_by_type` - Maps a resource identifier's `Alembic.ResourceIdentifier.type` and
    `Alembic.ResourceIdentifier.id` to its `Alembic.Resource.attributes` from
    `Alembic.Document.t` `included`.
  * `ecto_schema_module_by_type` -

  ## Returns

  * `nil` if an empty singleton
  * `struct` - if a non-empty singleton
  * `[]` - if an empty collection
  * `[struct]` - if a non-empty collection
  """
  @callback to_ecto_schema(struct, ToParams.resource_by_id_by_type, ecto_schema_module_by_type) :: ecto_schema

  @spec to_ecto_schema(ToParams.params, ecto_schema_module) :: struct
  # prefer to keep Ecto.Changeset instead of Changeset
  @lint {Credo.Check.Design.AliasUsage, false}
  def to_ecto_schema(params, ecto_schema_module) when is_atom(ecto_schema_module) do
    changeset = Ecto.Changeset.cast(ecto_schema_module.__struct__, params, ecto_schema_module.__schema__(:fields))
    struct(ecto_schema_module, changeset.changes)
  end

  @spec to_ecto_schema(%{type: Resource.type}, ToParams.params, ecto_schema_module_by_type) :: struct
  def to_ecto_schema(%{type: type}, params, ecto_schema_module_by_type) do
    ecto_schema_module = Map.fetch!(ecto_schema_module_by_type, type)
    to_ecto_schema(params, ecto_schema_module)
  end
end
