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
  alias Alembic.Resource
  alias Alembic.ResourceIdentifier
  alias Alembic.ToEctoSchema
  alias Alembic.ToParams

  @behaviour FromJson
  @behaviour ToEctoSchema
  @behaviour ToParams

  # Constants

  @human_type "resource linkage"

  # Functions

  @doc """
  Converts a resource linkage to one or more `Alembic.ResoureIdentifier.t`.

  ## To-one

  A to-one resource linkage, when present, can be a single `Alembic.Resource.t` or
  `Alembic.ResourceIdentifier.t`

  A JSON object is assumed to be an resource object if it has `"attributes"`

      iex> Alembic.ResourceLinkage.from_json(
      ...>   %{
      ...>     "attributes" => %{
      ...>       "name" => "Alice"
      ...>     },
      ...>     "id" => "1",
      ...>     "type" => "author"
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author/data"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Resource{
          attributes: %{
            "name" => "Alice"
          },
          id: "1",
          type: "author"
        }
      }

  Or if the JSON object has `"relationships"`

      iex> Alembic.ResourceLinkage.from_json(
      ...>   %{
      ...>     "id" => "1",
      ...>     "relationships" => %{
      ...>       "author" => %{
      ...>         "data" => %{
      ...>           "id" => "1",
      ...>           "type" => "author"
      ...>         }
      ...>       }
      ...>     },
      ...>     "type" => "post"
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Resource{
          id: "1",
          relationships: %{
            "author" => %Alembic.Relationship{
              data: %Alembic.ResourceIdentifier{
                id: "1",
                meta: nil,
                type: "author"
              }
            }
          },
          type: "post"
        }
      }

  If neither `"attributes"` nor `"relationships"` is present, then JSON object is assumed to be an
  `Alembic.ResourceIdentifier.t`.

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

  A to-many resource linkage, when present, can be a list of `Alembic.Resource.t`.

      iex> Alembic.ResourceLinkage.from_json(
      ...>   [
      ...>     %{
      ...>       "attributes" => %{
      ...>         "text" => "First Post!"
      ...>       },
      ...>       "id" => "1",
      ...>       "relationships" => %{
      ...>         "comments" => %{
      ...>           "data" => [
      ...>             %{
      ...>               "id" => "1",
      ...>               "type" => "comment"
      ...>             }
      ...>           ]
      ...>         }
      ...>       },
      ...>       "type" => "post"
      ...>     }
      ...>   ],
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        [
          %Alembic.Resource{
            attributes: %{
              "text" => "First Post!"
            },
            id: "1",
            links: nil,
            relationships: %{
              "comments" => %Alembic.Relationship{
                data: [
                  %Alembic.ResourceIdentifier{
                    id: "1",
                    type: "comment"
                  }
                ]
              }
            },
            type: "post"
          }
        ]
      }

  Or a list of `Alembic.ResourceIdentifier.t`.

      iex> Alembic.ResourceLinkage.from_json(
      ...>   [
      ...>     %{
      ...>       "id" => "1",
      ...>       "type" => "post"
      ...>     }
      ...>   ],
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        [
          %Alembic.ResourceIdentifier{
            id: "1",
            type: "post"
          }
        ]
      }

  A mix of resources and resource identifiers is an error

      iex> Alembic.ResourceLinkage.from_json(
      ...>   [
      ...>     %{
      ...>       "attributes" => %{
      ...>         "text" => "First Post!"
      ...>       },
      ...>       "id" => "1",
      ...>       "type" => "post"
      ...>     },
      ...>     %{
      ...>       "id" => "2",
      ...>       "type" => "post"
      ...>     }
      ...>   ],
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data` type is not resource linkage",
              meta: %{
                "type" => "resource linkage"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
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

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, Resource.t | ResourceIdentifier.t} | FromJson.error
  def from_json(json_object, error_template) when is_map(json_object) do
    resource_or_resource_identifier_from_json(json_object, error_template)
  end

  @spec from_json([Alembic.json_object, ...], Error.t) :: {:ok, [Resource.t | ResourceIdentifier.t]} | FromJson.error
  def from_json(json_array, error_template) when is_list(json_array) do
    json_array
    |> FromJson.from_json_array(error_template, &resource_or_resource_identifier_from_json/2)
    |> validate_consistent_types(error_template)
  end

  # Alembic.json -- [nil, [], Alembic.json_object, [Alembic.json_object]]
  @spec from_json(true | false | float | integer, Error.t) :: FromJson.error
  def from_json(_, error_template), do: type_error(error_template)

  @doc """
  Converts resource linkage to one or more [`Ecto.Schema.t`](http://hexdocs.pm/ecto/Ecto.Schema.html#t:t/0) structs.

  ## To-one

  An empty to-one, `nil`, is `nil` when converted to an Ecto Schema struct because no type information is available.

      iex> Alembic.ResourceLinkage.to_ecto_schema(nil, %{}, %{})
      nil

  A resource identifier uses `resource_by_id_by_type` to fill in the attributes of the referenced resource. `type` is
  dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types in the
  params.

      iex> Alembic.ResourceLinkage.to_ecto_schema(
      ...>   %Alembic.ResourceIdentifier{
      ...>     type: "shirt",
      ...>     id: "1"
      ...>   },
      ...>   %{
      ...>     "shirt" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "shirt",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         }
      ...>       }
      ...>     }
      ...>   },
      ...>   %{
      ...>     "shirt" => Alembic.TestShirt
      ...>   }
      ...> )
      %Alembic.TestShirt{
        __meta__: %Ecto.Schema.Metadata{
          source: {nil, "shirts"},
          state: :built
        },
        id: 1,
        size: "L"
      }

  On create or update, a relationship can be created by having an `Alembic.Resource.t`, in which case the
  attributes are supplied by the `Alembic.Resource.t`, instead of `resource_by_id_by_type`.

      iex> Alembic.ResourceLinkage.to_ecto_schema(
      ...>   %Alembic.Resource{
      ...>     attributes: %{
      ...>       "size" => "L"
      ...>     },
      ...>     type: "shirt"
      ...>   },
      ...>   %{},
      ...>   %{
      ...>     "shirt" => Alembic.TestShirt
      ...>   }
      ...> )
      %Alembic.TestShirt{
        __meta__: %Ecto.Schema.Metadata{
          source: {nil, "shirts"},
          state: :built
        },
        size: "L"
      }

  ## To-many

  An empty to-many, `[]`, is `[]` when converted because there is no type information available

      iex> Alembic.ResourceLinkage.to_ecto_schema(
      ...>   [],
      ...>   %{},
      ...>   %{}
      ...> )
      []

  A list of resource identifiers uses `resources_by_id_by_type` to fill in the attributes of the referenced resources.

      iex> Alembic.ResourceLinkage.to_ecto_schema(
      ...>   [
      ...>     %Alembic.ResourceIdentifier{
      ...>       type: "shirt",
      ...>       id: "1"
      ...>     }
      ...>   ],
      ...>   %{
      ...>     "shirt" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "shirt",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         }
      ...>       }
      ...>     }
      ...>   },
      ...>   %{
      ...>     "shirt" => Alembic.TestShirt
      ...>   }
      ...> )
      [
        %Alembic.TestShirt{
          __meta__: %Ecto.Schema.Metadata{
            source: {nil, "shirts"},
            state: :built
          },
          id: 1,
          size: "L"
        }
      ]

  On create or update, a relationship can be created by having an `Alembic.Resource`, in which case the
  attributes are supplied by the `Alembic.Resource`, instead of `resource_by_id_by_type`.

      iex> Alembic.ResourceLinkage.to_ecto_schema(
      ...>   [
      ...>     %Alembic.Resource{
      ...>       attributes: %{
      ...>         "size" => "L"
      ...>       },
      ...>       type: "shirt"
      ...>     }
      ...>   ],
      ...>   %{},
      ...>   %{
      ...>     "shirt" => Alembic.TestShirt
      ...>   }
      ...> )
      [
        %Alembic.TestShirt{
          __meta__: %Ecto.Schema.Metadata{
            source: {nil, "shirts"},
            state: :built
          },
          id: nil,
          size: "L"
        }
      ]

  """

  @spec to_ecto_schema(nil, ToParams.resource_by_id_by_type, ToEctoSchema.ecto_schema_module_by_type) :: nil
  def to_ecto_schema(nil, _, _), do: nil

  @spec to_ecto_schema([Resource.t] | [ResourceIdentifier.t],
                       ToParams.resource_by_id_by_type,
                       ToEctoSchema.ecto_schema_module_by_type) :: [struct]
  def to_ecto_schema(list, resource_by_id_by_type, ecto_schema_module_by_type) when is_list(list) do
    Enum.map list, &to_ecto_schema(&1, resource_by_id_by_type, ecto_schema_module_by_type)
  end

  @spec to_ecto_schema(Resource.t | ResourceIdentifier.t,
                       ToParams.resource_by_id_by_type,
                       ToEctoSchema.ecto_schema_module_by_type) :: struct

  def to_ecto_schema(resource_identifier = %ResourceIdentifier{}, resource_by_id_by_type, ecto_schema_module_by_type) do
    ResourceIdentifier.to_ecto_schema(resource_identifier, resource_by_id_by_type, ecto_schema_module_by_type)
  end

  def to_ecto_schema(resource = %Resource{}, resource_by_id_by_type, ecto_schema_module_by_type) do
    Resource.to_ecto_schema(resource, resource_by_id_by_type, ecto_schema_module_by_type)
  end

  @doc """
  Converts resource linkage to params format used by
  [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  ## To-one

  An empty to-one, `nil`, is `nil` when converted to params.

      iex> Alembic.ResourceLinkage.to_params(nil, %{})
      nil

  A resource identifier uses `resource_by_id_by_type` to fill in the attributes of the referenced resource. `type` is
  dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types in the
  params.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   %Alembic.ResourceIdentifier{
      ...>     type: "shirt",
      ...>     id: "1"
      ...>   },
      ...>   %{
      ...>     "shirt" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "shirt",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      %{
        "id" => "1",
        "size" => "L"
      }

  On create or update, a relationship can be created by having an `Alembic.Resource.t`, in which case the
  attributes are supplied by the `Alembic.Resource.t`, instead of `resource_by_id_by_type`.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   %Alembic.Resource{
      ...>     attributes: %{
      ...>       "size" => "L"
      ...>     },
      ...>     type: "shirt"
      ...>   },
      ...>   %{}
      ...> )
      %{
        "size" => "L"
      }

  ## To-many

  An empty to-many, `[]`, is `[]` when converted to params

      iex> Alembic.ResourceLinkage.to_params([], %{})
      []

  A list of resource identifiers uses `attributes_by_id_by_type` to fill in the attributes of the referenced resources.
  `type` is dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types
  in the params.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   [
      ...>     %Alembic.ResourceIdentifier{
      ...>       type: "shirt",
      ...>       id: "1"
      ...>     }
      ...>   ],
      ...>   %{
      ...>     "shirt" => %{
      ...>       "1" => %Alembic.Resource{
      ...>         type: "shirt",
      ...>         id: "1",
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         }
      ...>       }
      ...>     }
      ...>  }
      ...> )
      [
        %{
          "id" => "1",
          "size" => "L"
        }
      ]

  On create or update, a relationship can be created by having an `Alembic.Resource`, in which case the
  attributes are supplied by the `Alembic.Resource`, instead of `attributes_by_id_by_type`.

      iex> Alembic.ResourceLinkage.to_params(
      ...>   [
      ...>     %Alembic.Resource{
      ...>       attributes: %{
      ...>         "size" => "L"
      ...>       },
      ...>       type: "shirt"
      ...>     }
      ...>   ],
      ...>   %{}
      ...> )
      [
        %{
          "size" => "L"
        }
      ]

  """
  @spec to_params([Resource.t | ResourceIdentifier.t] | Resource.t | ResourceIdentifier.t | nil,
                  ToParams.resource_by_id_by_type) :: ToParams.params

  def to_params(nil, %{}), do: nil

  def to_params(list, resource_by_id_by_type) when is_list(list) do
    Enum.map list, &to_params(&1, resource_by_id_by_type)
  end

  def to_params(resource = %Resource{}, resource_by_id_by_type) do
    Resource.to_params(resource, resource_by_id_by_type)
  end

  def to_params(resource_identifier = %ResourceIdentifier{}, resource_by_id_by_type) do
    ResourceIdentifier.to_params(resource_identifier, resource_by_id_by_type)
  end

  ## Private Functions

  defp consistent_types?(list) when is_list(list) do
    list
    |> Enum.into(MapSet.new, fn element ->
          element.__struct__
       end)
    |> MapSet.size == 1
  end

  defp resource_or_resource_identifier_from_json(json = %{"attributes" => _}, error_template) do
    Resource.from_json(json, error_template)
  end

  defp resource_or_resource_identifier_from_json(json = %{"relationships" => _}, error_template) do
    Resource.from_json(json, error_template)
  end

  defp resource_or_resource_identifier_from_json(json, error_template) do
    ResourceIdentifier.from_json(json, error_template)
  end

  defp validate_consistent_types(collectable_result = {:error, _}, _), do: collectable_result

  defp validate_consistent_types(collectable_result = {:ok, list}, error_template) when is_list(list) do
    if consistent_types?(list) do
      collectable_result
    else
      type_error(error_template)
    end
  end

  defp type_error(error_template) do
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
