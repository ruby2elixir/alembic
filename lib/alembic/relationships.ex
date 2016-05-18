defmodule Alembic.Relationships do
  @moduledoc """
  > The value of the `relationships` key MUST be an object (a "relationships object"). Members of the relationships
  > object ("relationships") represent references from the resource object in which it's defined to other resource
  > objects.
  >
  > Relationships may be to-one or to-many.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-object-relationships)
  > </cite>
  """

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.Relationship
  alias Alembic.ToEctoSchema
  alias Alembic.ToParams

  @behaviour FromJson
  @behaviour ToEctoSchema
  @behaviour ToParams

  # Constants

  @human_type "relationships object"

  # Types

  @type relationship :: Alembic.json_object

  @typedoc """
  Maps `String.t` name to `relationship`
  """
  @type t :: %{String.t => relationship}

  # Functions

  @doc """
  Validates that the given `json` follows the spec for
  ["relationship"](http://jsonapi.org/format/#document-resource-object-relationships).

  `"relationships"` is optional, so it can be nil.

      iex> Alembic.Relationships.from_json(
      ...>   nil,
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships"
      ...>     }
      ...>   }
      ...> )
      {:ok, nil}

  ## Relationships

  > Members of the relationships object ("relationships") represent references from the resource object in which it's
  > defined to other resource objects.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-object-relationships)
  > </cite>

      iex> Alembic.Relationships.from_json(
      ...>   %{"shirt" => []},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/shirt` type is not relationship",
              meta: %{
                "type" => "relationship"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/shirt"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ## Data

  > Resource linkage in a compound document allows a client to link together all of the included resource objects
  > without having to `GET` any URLs via links.
  >
  > Resource linkage **MUST** be represented as one of the following:
  >
  > * `null` for empty to-one relationships.
  > * an empty array (`[]`) for empty to-many relationships.
  > * a single resource identifier object for non-empty to-one relationships.
  > * an array of resource identifier objects for non-empty to-many relationships.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Resource Linkage](http://jsonapi.org/format/#document-resource-object-linkage)
  > </cite>

  ### To-one

  A to-one relationship, when present, will be a single `Alembic.ResourceIdentifier.t`

      iex> Alembic.Relationships.from_json(
      ...>   %{
      ...>     "author" => %{
      ...>       "data" => %{
      ...>         "id" => "1",
      ...>         "type" => "author"
      ...>       }
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %{
          "author" => %Alembic.Relationship{
            data: %Alembic.ResourceIdentifier{
              id: "1",
              type: "author"
            }
          }
        }
      }

  An empty to-one relationship can be signified with `nil`, which would have been `null` in the original JSON.

      iex> Alembic.Relationships.from_json(
      ...>   %{
      ...>     "author" => %{
      ...>       "data" => nil
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %{
          "author" => %Alembic.Relationship{
            data: nil
          }
        }
      }

  ### To-many

  A to-many relationship, when preent, will be a list of `Alembic.ResourceIdentifier.t`

      iex> Alembic.Relationships.from_json(
      ...>   %{
      ...>     "comments" => %{
      ...>       "data" => [
      ...>         %{
      ...>           "id" => "1",
      ...>           "type" => "comment"
      ...>         }
      ...>       ]
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %{
          "comments" => %Alembic.Relationship{
            data: [
              %Alembic.ResourceIdentifier{
                id: "1",
                type: "comment"
              }
            ]
          }
        }
      }

  An empty to-many resource linkage can be signified with `[]`.

      iex> Alembic.Relationships.from_json(
      ...>   %{
      ...>     "comments" => %{
      ...>       "data" => []
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %{
          "comments" => %Alembic.Relationship{
            data: []
          }
        }
      }


  """
  def from_json(json, error_template)

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, map} | FromJson.error
  def from_json(relationship_by_name, error_template = %Error{}) when is_map(relationship_by_name) do
    relationship_by_name
    |> Stream.map(&relationship_key_result_from_key_json_pair(&1, error_template))
    |> FromJson.reduce({:ok, %{}})
  end

  @spec from_json(nil, Error.t) :: {:ok, nil}
  def from_json(nil, _), do: {:ok, nil}

  # Alembic.json -- [Alembic.json_object, nil]
  @spec from_json(true | false | list | float | integer | String.t, Error.t) :: FromJson.error
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

  @doc """
  Converts relationships to map of the relationship's struct(s) that can be merged with the struct for the primary data

  ## No relationships

  No relationships are represented as `nil` in `IntrepreterServer.Api.Document.t`, but since the output of
  `to_ecto_schema/2` is expected to be `struct/2` combinable with the primary resource's struct, an empty map is
  returned when relationships is `nil`.

      iex> Alembic.Relationships.to_ecto_schema(nil, %{}, %{})
      %{}

  ## Some Relationships

  Relatonships are expected to be `struct/2` combinable with the primary resource's struct, so relationships are
  returned as a map using the original relationship name and each `Alembic.Relationship.t` converted with
  `Alembic.Relationship.to_ecto_schema/3`.

  ### Resource Identifiers

  If the resource linkage for a relationship is an `Alembic.ResourceIdentifier.t`, then the attributes for
  the resource will be looked up in `resource_by_id_by_type`.

      iex> Alembic.Relationships.to_ecto_schema(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.ResourceIdentifier{id: "1", type: "author"}
      ...>     }
      ...>   },
      ...>   %{
      ...>     "author" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "author",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "name" => "Alice"
      ...>         }
      ...>       }
      ...>     }
      ...>   },
      ...>   %{
      ...>     "author" => Alembic.TestAuthor
      ...>   }
      ...> )
      %{
        "author" => %Alembic.TestAuthor{
          __meta__: %Ecto.Schema.Metadata{
            source: {nil, "authors"},
            state: :built
          },
          id: 1,
          name: "Alice"
        }
      }

  Resources are not required to be in `resources_by_id_by_type`, as would be the case when only a foreign key is
  supplied.

      iex> Alembic.Relationships.to_ecto_schema(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.ResourceIdentifier{id: "1", type: "author"}
      ...>     }
      ...>   },
      ...>   %{},
      ...>   %{
      ...>     "author" => Alembic.TestAuthor
      ...>   }
      ...> )
      %{
        "author" => %Alembic.TestAuthor{
          __meta__: %Ecto.Schema.Metadata{
            source: {nil, "authors"},
            state: :built
          },
          id: 1
        }
      }

  ### Resources

  On create or update, the relationships can directly contain `Alembic.Resource.t` that are to be created,
  in which case the `resource_by_id_by_type` are ignored.

      iex> Alembic.Relationships.to_ecto_schema(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.Resource{
      ...>         attributes: %{"name" => "Alice"},
      ...>         type: "author"
      ...>       }
      ...>     },
      ...>   },
      ...>   %{},
      ...>   %{
      ...>     "author" => Alembic.TestAuthor
      ...>   }
      ...> )
      %{
        "author" => %Alembic.TestAuthor{
          __meta__: %Ecto.Schema.Metadata{
            source: {nil, "authors"},
            state: :built
          },
          name: "Alice"
        }
      }
  """

  @spec to_ecto_schema(nil, ToParams.resource_by_id_by_type, ToEctoSchema.ecto_schema_module_by_type) :: map
  def to_ecto_schema(nil, _, _), do: %{}

  @spec to_ecto_schema(t, ToParams.resource_by_id_by_type, ToEctoSchema.ecto_schema_module_by_type) :: map
  def to_ecto_schema(relationship_by_name, resource_by_id_by_type, ecto_schema_module_by_type) do
    Enum.into relationship_by_name, %{}, fn {name, relationship} ->
      {name, Relationship.to_ecto_schema(relationship, resource_by_id_by_type, ecto_schema_module_by_type)}
    end
  end

  @doc """
  Converts relationships to params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) that can be merged with the params
  from the primary data.

  ## No relationships

  No relationships are represented as `nil` in `Alembic.Document.t`, but since the output of
  `to_params/2` is expected to be `Map.merge/2` with the primary resource's params, an empty map is returned when
  relationships is `nil`.

      iex> Alembic.Relationships.to_params(nil, %{})
      %{}

  ## Some Relationships

  Relatonship params are expected to be `Map.merge/2` with the primary resource's params, so a relationships are
  returned as a map using the original relationship name and each `Alembic.Relationship.t` converted with
  `Alembic.Relationship.to_params/2`.

  ### Resource Identifiers

  If the resource linkage for a relationship is an `Alembic.ResourceIdentifier.t`, then the attributes for
  the resource will be looked up in `resource_by_id_by_type`.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.ResourceIdentifier{id: "1", type: "author"}
      ...>     }
      ...>   },
      ...>   %{
      ...>     "author" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "author",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "name" => "Alice"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      %{
        "author" => %{
          "id" => "1",
          "name" => "Alice"
        }
      }

  Resources are not required to be in `resources_by_id_by_type`, as would be the case when only a foreign key is
  supplied.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.ResourceIdentifier{id: "1", type: "author"}
      ...>     }
      ...>   },
      ...>   %{}
      ...> )
      %{
        "author" => %{
          "id" => "1"
        }
      }

  ### Resources

  On create or update, the relationships can directly contain `Alembic.Resource.t` that are to be created,
  in which case the `resource_by_id_by_type` are ignored.

      iex> Alembic.Relationships.to_params(
      ...>   %{
      ...>     "author" => %Alembic.Relationship{
      ...>       data: %Alembic.Resource{
      ...>         attributes: %{"name" => "Alice"},
      ...>         type: "author"
      ...>       }
      ...>     },
      ...>   },
      ...>   %{}
      ...> )
      %{
        "author" => %{
          "name" => "Alice"
        }
      }
  """

  @spec to_params(nil, ToParams.resource_by_id_by_type) :: %{}
  def to_params(nil, _), do: %{}

  @spec to_params(t, ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(relationship_by_name = %{}, resource_by_id_by_type = %{}) do
    Enum.into relationship_by_name, %{}, fn {name, relationship} ->
      {name, Relationship.to_params(relationship, resource_by_id_by_type)}
    end
  end

  ## Private Functions

  defp relationship_key_result_from_key_json_pair({key, value_json}, parent_error_template) do
    key_error_template = Error.descend(parent_error_template, key)

    value_json
    |> Relationship.from_json(key_error_template)
    |> FromJson.put_key(key)
  end
end
