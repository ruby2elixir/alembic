defmodule Alembic.ResourceLinkage do
  @moduledoc """
  > Resource linkage in a compound document allows a client to link together all of the included resource objects
  > without having to `GET` any URLs via links.
  >
  > Resource linkage **MUST** be represented as one of the following:

  > * `null` for empty to-one relationships.
  > * an empty array (`[]`) for empty to-many relationships.
  > * a single resource identifier object for non-empty to-one relationships.
  > * an array of resource identifier objects for non-empty to-many relationships.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Resource Linkage](http://jsonapi.org/format/#document-resource-object-linkage)
  > </cite>
  """

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.ResourceIdentifier

  @behaviour FromJson

  # Constants

  @human_type "resource linkage"

  # Functions

  @doc """
  Converts a resource linkage to one or more `Alembic.ResoureIdentifier.t`.

  ## To-one

  A to-one resource linkage, when present, will be a single `Alembic.ResourceIdentifier.t`

      iex> Alembic.ResourceLinkage.from_json(
      ...>   %{
      ...>     "id" => "1",
      ...>     "type" => "author"
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author/data"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.ResourceIdentifier{
          id: "1",
          type: "author"
        }
      }

  An empty to-one resource linkage can be signified with `nil`, which would have been `null` in the original JSON.

      iex> Alembic.ResourceLinkage.from_json(
      ...>   nil,
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author/data"
      ...>     }
      ...>   }
      ...> )
      {:ok, nil}

  ## To-many

  A to-many resource linkage, when preent, will be a list of `Alembic.ResourceIdentifier.t`

      iex> Alembic.ResourceLinkage.from_json(
      ...>   [
      ...>     %{
      ...>       "id" => "1",
      ...>       "type" => "comment"
      ...>     }
      ...>   ],
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/comments/data"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        [
          %Alembic.ResourceIdentifier{
            id: "1",
            type: "comment"
          }
        ]
      }

  An empty to-many resource linkage can be signified with `[]`.

      iex> Alembic.ResourceLinkage.from_json(
      ...>   [],
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/comments/data"
      ...>     }
      ...>   }
      ...> )
      {:ok, []}

  ## Invalid

  If the `json` isn't any of the above, valid formats, then a type error will be returned

      iex> Alembic.ResourceLinkage.from_json(
      ...>   "that resource over there",
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/resource/data"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/resource/data` type is not resource linkage",
              meta: %{
                "type" => "resource linkage"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/resource/data"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  """
  def from_json(json, error_template)

  @spec from_json(nil, Error.t) :: {:ok, nil}
  def from_json(nil, _), do: {:ok, nil}

  @spec from_json([], Error.t) :: {:ok, []}
  def from_json([], _), do: {:ok, []}

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, ResourceIdentifier.t} | FromJson.error
  def from_json(resource_identifier_json, error_template) when is_map(resource_identifier_json) do
    ResourceIdentifier.from_json(resource_identifier_json, error_template)
  end

  @spec from_json([Alembic.json_object, ...], Error.t) :: {:ok, [ResourceIdentifier.t]} | FromJson.error
  def from_json(resource_identifiers_json, error_template) when is_list(resource_identifiers_json) do
    FromJson.from_json_array(resource_identifiers_json, error_template, ResourceIdentifier)
  end

  # Alembic.json -- [nil, [], Alembic.json_object, [Alembic.json_object]]
  @spec from_json(true | false | float | integer, Error.t) :: FromJson.error
  def from_json(_, error_template) do
    {
      :error,
      %Document{
        errors: [
          Error.type(error_template, @human_type)
        ]
      }
    }
  end
end
