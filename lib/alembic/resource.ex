defmodule Alembic.Resource do
  @moduledoc """
  The individual JSON object of elements of the list of the `data` member of the
  [JSON API document](http://jsonapi.org/format/#document-structure) are
  [resources](http://jsonapi.org/format/#document-resource-objects) as are the members of the `included` member.
  """

  alias Alembic
  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.Links
  alias Alembic.Meta
  alias Alembic.Relationships

  @behaviour FromJson

  # Constants

  @attributes_human_type "json object"

  @attributes_options %{
                        field: :attributes,
                        member: %{
                          name: "attributes"
                        }
                      }

  @id_options %{
                field: :id,
                member: %{
                  from_json: &FromJson.string_from_json/2,
                  name: "id"
                }
              }

  @links_options %{
                   field: :links,
                   member: %{
                     module: Links,
                     name: "links"
                   }
                 }

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  }
                }

  @relationships_options %{
                           field: :relationships,
                           member: %{
                             module: Relationships,
                             name: "relationships"
                           }
                         }

  @type_options %{
                  field: :type,
                  member: %{
                    from_json: &FromJson.string_from_json/2,
                    name: "type",
                    required: true
                  }
                }

  # DOES NOT include `@attribute_options` because it needs to be customized with private function reference
  # DOES NOT include `@id_options` because it needs to be customized based on `error_template.meta`
  @child_options_list [
    @links_options,
    @meta_options,
    @relationships_options,
    @type_options
  ]

  @human_type "resource"

  # Struct

  defstruct attributes: nil,
            id: nil,
            links: nil,
            meta: nil,
            relationships: nil,
            type: nil

  # Types

  @typedoc """
  Resource objects" appear in a JSON API document to represent resources.

  A resource object **MUST** contain at least the following top-level members:

  * `id`
  * `type`

  Exception: The `id` member is not required when the resource object originates at the client and represents a new
  resource to be created on the server. (`%{action: :create, source: :client}`)

  In addition, a resource object **MAY(( contain any of these top-level members:

  * `attributes` - an [attributes object](http://jsonapi.org/format/#document-resource-object-attributes) representing
    some of the resource's data.
  * `links` - an `Alembic.Link.links` containing links related to the resource.
  * `meta` - contains non-standard meta-information about a resource that can not be represented as an attribute or
    relationship.
  * `relationships` - a [relationships object](http://jsonapi.org/format/#document-resource-object-relationships)
    describing relationships between the resource and other JSON API resources.
  """
  @type t :: %__MODULE__{
               attributes: Alembic.json_object | nil,
               id: String.t | nil,
               links: Links.t | nil,
               meta: Meta.t | nil,
               relationships: Relationships.t | nil,
               type: String.t
             }

  # Functions

  @doc """
  Converts a JSON object into a [JSON API Resource](http://jsonapi.org/format/#document-resource-objects), `t`.


  ## Invalid

  A non-resource will be matched, but return an error.

      iex> Alembic.Resource.from_json(
      ...>   "1",
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
              detail: "`/data` type is not resource",
              meta: %{
                "type" => "resource"
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

  ## Action

  The `Alembic.Error.t` `meta` `"action"` key influences whether `"id"` is required: `"id"` is optional
  for `"action"` `:create` sent from `"sender"` `:client`; otherwise, it `"id"` is required.

  ### Creating

  Only `"type"` is required when creating a resource from a client because the `"id"` will be assigned by the server.

      iex> Alembic.Resource.from_json(
      ...>   %{ "type" => "thing" },
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
      {:ok, %Alembic.Resource{type: "thing"}}

  Only `"type"` will be marked as missing when creating a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{},
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
              detail: "`/data/type` is missing",
              meta: %{
                "child" => "type"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  But, normally you'd include some `"attributes"` too

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "attributes" => %{
      ...>       "name" => "Thing 1"
      ...>     },
      ...>     "type" => "thing"
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
          attributes: %{
            "name" => "Thing 1"
          },
          type: "thing"
        }
      }

  `"attributes"` are quite free-form, but must still be an `Alembic.json_object`

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "attributes" => [
      ...>       "name"
      ...>     ],
      ...>     "type" => "thing"
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
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/attributes` type is not json object",
              meta: %{
                "type" => "json object"
              },
              source: %Alembic.Source{
                pointer: "/data/attributes"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ### Deleting

  Only `"id"` and `"type"` is required when when deleting a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{ "id" => "1", "type" => "thing"},
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :delete,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.Resource{id: "1", type: "thing"}}

  With `"id"`, `"type"` will be marked as missing when deleting a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{ "id" => "1" },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :delete,
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
              detail: "`/data/type` is missing",
              meta: %{
                "child" => "type"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  With `"type"`, `"id"` will be marked as missing when deleting a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{ "type" => "thing" },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :delete,
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
              detail: "`/data/id` is missing",
              meta: %{
                "child" => "id"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  Both `"id"` and `"type"` will be marked as missing when deleting a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :delete,
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
              detail: "`/data/id` is missing",
              meta: %{
                "child" => "id"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            },
            %Alembic.Error{
              detail: "`/data/type` is missing",
              meta: %{
                "child" => "type"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  ### Updating

  Only `"id"` and `"type"` is required when when updating a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{ "id" => "1", "type" => "thing"},
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :update,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.Resource{id: "1", type: "thing"}}

  With `"id"`, `"type"` will be marked as missing when upating a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{ "id" => "1" },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :update,
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
              detail: "`/data/type` is missing",
              meta: %{
                "child" => "type"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  With `"type"`, `"id"` will be marked as missing when updating a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{ "type" => "thing" },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :update,
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
              detail: "`/data/id` is missing",
              meta: %{"child" => "id"},
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  Both `"id"` and `"type"` will be marked as missing when updating a resource from a client

      iex> Alembic.Resource.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :update,
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
              detail: "`/data/id` is missing",
              meta: %{"child" => "id"},
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            },
            %Alembic.Error{
              detail: "`/data/type` is missing",
              meta: %{
                "child" => "type"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  ## Optional members

  `"links"`, `"meta"` and `"relationships"` are optional, but if they are present, they **MUST** be valid or their
  errors will make the overall `t` invalid.

  ### `"links"`

  A valid `"links"` maps link names to either a JSON object with `"href"` and/or `"meta"` member or a `String.t` URL.

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "links" => %{
      ...>        "string" => "http://example.com",
      ...>       "link_object" => %{
      ...>         "href" => "http://example.com",
      ...>         "meta" => %{
      ...>           "last_updated_on" => "2015-12-21"
      ...>         }
      ...>       }
      ...>     },
      ...>     "type" => "thing"
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
          links: %{
            "link_object" => %Alembic.Link{
              href: "http://example.com",
              meta: %{
                "last_updated_on" => "2015-12-21"
              }
            },
            "string" => "http://example.com"
          },
          type: "thing"
        }
      }

  Even though `"links"` is optional, if it has errors, those errors will make the entire resource invalid

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "links" => ["http://example.com"],
      ...>     "type" => "thing"
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
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/links` type is not links object",
              meta: %{
                "type" => "links object"
              },
              source: %Alembic.Source{
                pointer: "/data/links"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ### `"meta"`

  A valid `"meta"` is any JSON object

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "meta" => %{"copyright" => "© 2015"},
      ...>     "type" => "thing"
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
          meta: %{
            "copyright" => "© 2015"
          },
          type: "thing"
        }
      }

  If `"meta"` isn't a JSON object, then that error will make the whole resource invalid

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "meta" => "© 2015",
      ...>     "type" => "thing"
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
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/meta` type is not meta object",
              meta: %{
                "type" => "meta object"
              },
              source: %Alembic.Source{
                pointer: "/data/meta"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ### Relationships

  `"relationships"` allow linking to other resource in the documents `"included"` using resource identifiers

      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "relationships" => %{
      ...>       "shirt" => %{
      ...>         "data" => %{
      ...>           "id" => "1",
      ...>           "type" => "shirt"
      ...>         }
      ...>       }
      ...>     },
      ...>     "type" => "thing"
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
          relationships: %{
            "shirt" => %Alembic.Relationship{
              data: %Alembic.ResourceIdentifier{
                id: "1",
                type: "shirt"
              }
            }
          },
          type: "thing"
        }
      }

  If any relationship has an error, then it will make the entire resource invalid


      iex> Alembic.Resource.from_json(
      ...>   %{
      ...>     "relationships" => %{
      ...>       "shirt" => %{
      ...>         "data" => %{}
      ...>       }
      ...>     },
      ...>     "type" => "thing"
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
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/shirt/data/type` is missing",
              meta: %{
                "child" => "type"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/shirt/data"
              },
              status: "422",
              title: "Child missing"
            },
            %Alembic.Error{
              detail: "`/data/relationships/shirt/data/id` is missing",
              meta: %{
                "child" => "id"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/shirt/data"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  """
  def from_json(json, error_template)

  @spec from_json(Alembic.json_object, %Error{meta: Meta.t}) :: {:ok, t} | FromJson.error
  def from_json(json, error_template = %Error{meta: meta}) when is_map(json) do
    parent = %{error_template: error_template, json: json}

    meta
    |> child_options_list_from_meta
    |> Stream.map(&Map.put(&1, :parent, parent))
    |> Stream.map(&FromJson.from_parent_json_to_field_result/1)
    |> FromJson.reduce({:ok, %__MODULE__{}})
  end

  # Alembic.json -- [Alembic.json_object]
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

  ## Private Functions

  @spec attributes_from_json(Alembic.json_object, Error.t) :: {:ok, Alembic.json_object}
  defp attributes_from_json(attributes, _) when is_map(attributes), do: {:ok, attributes}

  # the rest of Alembic.json
  @spec attributes_from_json(nil | true | false | float | integer | String.t, Error.t) :: FromJson.error
  defp attributes_from_json(_, error_template) do
    {
      :error,
      %Document{
        errors: [
          Error.type(error_template, @attributes_human_type)
        ]
      }
    }
  end

  # **MUST** be a function so it can capture reference to private `attributes_from_json/2`
  @spec attributes_options() :: map
  defp attributes_options do
    put_in @attributes_options[:member][:from_json], &attributes_from_json/2
  end

  # Specializes the child_options_list based on `"action"` and `"sender"` in `meta`
  #
  # If the `"action"` is `:create` and the `"sender"` is `:client`, then `"id" is not required; otherwise,
  # the `"id" is required.
  @spec child_options_list_from_meta(map) :: [map, ...]
  defp child_options_list_from_meta(meta) do
    [attributes_options, id_options_from_meta(meta) | @child_options_list]
  end

  @spec id_options_from_meta(%{String.t => atom}) :: map

  defp id_options_from_meta(%{"action" => :create, "sender" => :client}) do
    put_in @id_options[:member][:required], false
  end

  # action is `FromJson @actions` -- [:create]
  defp id_options_from_meta(%{"action" => action, "sender" => sender}) when (action in [:delete, :fetch, :update] and
                                                                             sender in [:client, :server]) or
                                                                            (action == :create and sender == :server) do
    put_in @id_options[:member][:required], true
  end

  # Protocol Implementations

  defimpl Poison.Encoder do
    alias Alembic.Resource

    @doc """
    Only non-`nil` members are encoded

        iex> Poison.encode(
        ...>   %Alembic.Resource{
        ...>     type: "post"
        ...>   }
        ...> )
        {:ok, "{\\"type\\":\\"post\\"}"}

    But, `type` is always required, so without it, an exception is raised.

        iex> try do
        ...>   Poison.encode(%Alembic.Resource{})
        ...> rescue
        ...>   e in FunctionClauseError -> e
        ...> end
        %FunctionClauseError{arity: 2, function: :encode, module: Poison.Encoder.Alembic.Resource}

    """
    def encode(resource = %Resource{type: type}, options) when not is_nil(type) do
      # strip `nil` so that resources without id for create don't end up with `"id": null` after encoding
      map = for {field, value} <- Map.from_struct(resource), value != nil, into: %{}, do: {field, value}

      Poison.Encoder.Map.encode(map, options)
    end
  end
end
