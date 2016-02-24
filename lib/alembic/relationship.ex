defmodule Alembic.Relationship do
  @moduledoc """
  > Members of the relationships object ("relationships") represent references from the resource object in which it's
  > defined to other resource objects.
  >
  > Relationships may be to-one or to-many.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-objects-relationships)
  > </cite>
  """

  alias Alembic
  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.Links
  alias Alembic.Meta
  alias Alembic.ResourceLinkage
  alias Alembic.ToParams

  @behaviour FromJson
  @behaviour ToParams

  # Constants

  @data_options %{
                  field: :data,
                  member: %{
                    module: ResourceLinkage,
                    name: "data"
                  },
                  parent: nil
                }

  @human_type "relationship"

  @links_options %{
                   field: :links,
                   member: %{
                     module: Links,
                     name: "links"
                   },
                   parent: nil
                 }

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  },
                  parent: nil
                }
  # Struct

  defstruct data: nil,
            links: nil,
            meta: nil

  # Types

  @type resource_identifier :: %{String.t => String.t}

  @typedoc """
  > A "relationship object" **MUST** contain at least one of the following:
  >
  > * `links` - a links object containing at least one of the following:
  >     * `self` - a link for the relationship itself (a "relationship link"). This link allows the client to directly
  >        manipulate the relationship. For example, removing an author through an article's relationship URL would
  >        disconnect the person from the article without deleting the people resource itself. When fetched
  >        successfully, this link returns the linkage for the related resources as its primary data. (See Fetching
  >        Relationships.)
  >     * `related` - a related resource link
  > * `data` - resource linkage
  > * `meta` - a meta object that contains non-standard meta-information about the relationship.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Objects -
  >   Relationships](http://jsonapi.org/format/#document-resource-objects-relationships)
  > </cite>
  """
  @type t :: %__MODULE__{
               data: [resource_identifier] | resource_identifier,
               links: Links.links,
               meta: Alembic.meta
             }

  # Functions

  @doc """

  # Relationships

  A non-object will be matched, but return an error.

      iex> Alembic.Relationship.from_json(
      ...>   "1",
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/author` type is not relationship",
              meta: %{
                "type" => "relationship"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/author"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  An object without any of the members will show them as all missing

      iex> Alembic.Relationship.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "At least one of the following children of `/data/relationships/author` must be present:\\n" <>
                      "data\\n" <>
                      "links\\n" <>
                      "meta",
              meta: %{
                "children" => [
                  "data",
                  "links",
                  "meta"
                ]
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/author"
              },
              status: "422",
              title: "Not enough children"
            }
          ]
        }
      }

  ## Resource Linkage

  ### To-one

  `"data"` can be a single resource identifier

      iex> Alembic.Relationship.from_json(
      ...>   %{"data" => %{"id" => "1", "type" => "author"}},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Relationship{
          data: %Alembic.ResourceIdentifier{
            id: "1",
            type: "author"
          }
        }
      }

  An empty to-one relationship can be signified with `nil` for `"data"`

      iex> Alembic.Relationship.from_json(
      ...>   %{"data" => nil},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/author"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.Relationship{data: nil}}

  ### To-many

  `"data"` can be a list of resource identifiers

      iex> Alembic.Relationship.from_json(
      ...>   %{
      ...>     "data" => [
      ...>       %{"id" => "1", "type" => "comment"},
      ...>       %{"id" => "2", "type" => "comment"}
      ...>     ]
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/comments"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Relationship{
          data: [
            %Alembic.ResourceIdentifier{id: "1", type: "comment"},
            %Alembic.ResourceIdentifier{id: "2", type: "comment"}
          ]
        }
      }

  An empty to-many relationship can be signified with `[]`

      iex> Alembic.Relationship.from_json(
      ...>   %{"data" => []},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/comments"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.Relationship{data: []}}

  ### Invalid

  There are actual, invalid values for resource linkages, such as strings and numbers

      iex> Alembic.Relationship.from_json(
      ...>   %{"data" => "bad resource linkage"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/bad"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/bad/data` type is not resource linkage",
              meta: %{
                "type" => "resource linkage"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/bad/data"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ## Links

  `"links"` if present, must be an object

      iex> Alembic.Relationship.from_json(
      ...>   %{"links" => ["http://example.com"]},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/website"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/website/links` type is not links object",
              meta: %{
                "type" => "links object"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/website/links"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  Because the "links" name are free-form, they remain strings

      iex> Alembic.Relationship.from_json(
      ...>   %{"links" => %{"example" => "http://example.com"}},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/website"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Relationship{
          links: %{
            "example" => "http://example.com"
          }
        }
      }

  "links" can be mix of `String.t` URLs and `Alembic.Link.t` objects

      iex> Alembic.Relationship.from_json(
      ...>   %{
      ...>     "links" => %{
      ...>       "link_object" => %{
      ...>          "href" => "http://example.com/link_object/href"
      ...>       },
      ...>       "string" => "http://example.com/string"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/website"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Relationship{
          links: %{
            "link_object" => %Alembic.Link{
              href: "http://example.com/link_object/href"
            },
            "string" => "http://example.com/string"
          }
        }
      }
  """
  def from_json(json, error_template)

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, t} | FromJson.error
  def from_json(json = %{}, error_template = %Error{}) do
    parent = %{error_template: error_template, json: json}

    data_result = FromJson.from_parent_json_to_field_result %{@data_options | parent: parent}
    links_result = FromJson.from_parent_json_to_field_result %{@links_options | parent: parent}
    meta_result = FromJson.from_parent_json_to_field_result %{@meta_options | parent: parent}
    results = [data_result, links_result, meta_result]

    if Enum.all? results, &(&1 == :error) do
      {
        :error,
        %Document{
          errors: [
            Error.minimum_children(error_template, ~w{data links meta})
          ]
        }
      }
    else
      results
      |> FromJson.reduce({:ok, %__MODULE__{}})
    end
  end

  # Alembic.json - [Alembic.json_object]
  @spec from_json(nil | true | false | list | float | integer | String.t, Error.t) :: FromJson.error
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
  Converts `t` to params format used by [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4).

  ## To-one

  An empty to-one, `nil`, is `nil` when converted to params.

      iex> Alembic.Relationship.to_params(%Alembic.Relationship{data: nil}, %{})
      nil

  A resource identifier uses `resource_by_id_by_type` to fill in the attributes of the referenced resource. `type` is
  dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types in the
  params.

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: %Alembic.ResourceIdentifier{
      ...>       id: "1", type: "shirt"
      ...>     }
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

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: %Alembic.Resource{
      ...>       attributes: %{
      ...>         "size" => "L"
      ...>       },
      ...>       type: "shirt"
      ...>     }
      ...>   },
      ...>   %{}
      ...> )
      %{
        "size" => "L"
      }

  ## To-many

  An empty to-many, `[]`, is `[]` when converted to params

      iex> Alembic.Relationship.to_params(%Alembic.Relationship{data: []}, %{})
      []

  A list of resource identifiers uses `resource_by_id_by_type` to fill in the attributes of the referenced resources.
  `type` is dropped as [`Ecto.Changeset.cast/4`](http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) doesn't verify types
  in the params.

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: [
      ...>       %Alembic.ResourceIdentifier{
      ...>         id: "1", type: "shirt"
      ...>       }
      ...>     ]
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
      ...>  }
      ...> )
      [
        %{
          "id" => "1",
          "size" => "L"
        }
      ]

  On create or update, a relationship can be created by having an `Alembic.Resource.t`, in which case the
  attributes are supplied by the `Alembic.Resource`, instead of `resource_by_id_by_type`.

      iex> Alembic.Relationship.to_params(
      ...>   %Alembic.Relationship{
      ...>     data: [
      ...>       %Alembic.Resource{
      ...>         attributes: %{
      ...>           "size" => "L"
      ...>         },
      ...>         type: "shirt"
      ...>       }
      ...>     ]
      ...>   },
      ...>   %{}
      ...> )
      [
        %{
          "size" => "L"
        }
      ]

  """
  @spec to_params(%__MODULE__{data: any}, ToParams.resource_by_id_by_type) :: ToParams.params
  def to_params(%__MODULE__{data: data}, resource_by_id_by_type) do
    ResourceLinkage.to_params(data, resource_by_id_by_type)
  end
end
