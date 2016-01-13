defmodule Alembic.Document do
  @moduledoc """
  JSON API refers to the top-level JSON structure as a [document](http://jsonapi.org/format/#document-structure).
  """

  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.Links
  alias Alembic.Meta
  alias Alembic.Resource
  alias Alembic.ResourceLinkage

  # Behaviours

  @behaviour FromJson

  # Constants

  @data_options %{
                  field: :data,
                  member: %{
                    module: ResourceLinkage,
                    name: "data"
                  }
                }

  @errors_options %{
                    field: :errors,
                    member: %{
                      name: "errors"
                    }
                  }

  @included_options %{
                      field: :included,
                      member: %{
                        name: "included"
                      }
                    }

  @human_type "document"

  @links_options %{
                   field: :links,
                   member: %{
                     module: Links,
                     name: "links"
                   }
                 }

  @minimum_children ~w{data errors meta}

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  }
                }

  # DOES NOT include `@errors_options` because `&FromJson.from_json_array(&1, &2, Error)` cannot appear in a module
  #   attribute used in a function
  # DOES NOT include `@included_options` because `&FromJson.from_json_array(&1, &2, Resource)` cannot appear in a module
  #   attribute used in a function
  @child_options_list [
    @data_options,
    @links_options,
    @meta_options
  ]

  # Struct

  defstruct ~w{data errors included links meta}a

  # Types

  @typedoc """
  A JSON API [Document](http://jsonapi.org/format/#document-structure).

  ## Data

  When there are no errors, `data` are returned in the document and `errors` are not returned in the document.

  | Field      | Included/Excluded/Optional |
  |------------|----------------------------|
  | `data`     | Included                   |
  | `errors`   | Excluded                   |
  | `included` | Optional                   |
  | `links`    | Optional                   |
  | `meta`     | Optional                   |

  ## Errors

  When an error occurs, `errors` are returned in the document and `data` are not returned in the document.

  | Field      | Included/Excluded/Optional |
  |------------|----------------------------|
  | `data`     | Excluded                   |
  | `errors`   | Included                   |
  | `included` | Excluded                   |
  | `links`    | Optional                   |
  | `meta`     | Optional                   |

  ## Meta

  JSON API allows a `meta` only document, in which case `data` and `errors` are not returned in the document.

  | Field      | Included/Excluded/Optional |
  |------------|----------------------------|
  | `data`     | Excluded                   |
  | `errors`   | Excluded                   |
  | `included` | Excluded                   |
  | `links`    | Optional                   |
  | `meta`     | Included                   |

  """
  @type t :: %__MODULE__{
               data: nil,
               errors: [Error.t],
               included: nil,
               links: Links.t | nil,
               meta: Meta.t | nil
             } |
             %__MODULE__{
               data: nil,
               errors: nil,
               included: nil,
               links: Links.t | nil,
               meta: Meta.t
             } |
             %__MODULE__{
               data: [Resource.t] | Resource.t,
               errors: nil,
               included: [Resource.t] | nil,
               links: Links.t | nil,
               meta: Meta.t | nil
             }

  # Functions

  @doc """
  Converts a JSON object into a JSON API Document, `t`.

  ## Data documents

  ### Single

  An empty single resource can represented as `"data": null` in encoded JSON, so it comes into `from_json` as
  `data: nil`

      iex> Alembic.Document.from_json(
      ...>   %{ "data" => nil },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          data: nil
        }
      }

  A present single can be a resource

      iex> Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => %{
      ...>       "attributes" => %{
      ...>         "text" => "First Post!"
      ...>       },
      ...>       "id" => "1",
      ...>       "type" => "post"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :client
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          data: %Alembic.Resource{
            attributes: %{
              "text" => "First Post!"
            },
            id: "1",
            type: "post"
          }
        }
      }

  ... or a present single can be just a resource identifier

      iex> Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => %{
      ...>       "id" => "1",
      ...>       "type" => "post"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          data: %Alembic.ResourceIdentifier{
            id: "1",
            type: "post"
          }
        }
      }

  You notice that whether a JSON object in `"data"` is treated as a `Alembic.Resource.t` or
  `Alembic.ResourceIdentifier.t` hinges on whether `"attributes"` or `"relationships"` is present as those
  members are only allowed for resources.

  ### Collection

  #### Resources

  A collection can be a list of resources

     iex> Alembic.Document.from_json(
     ...>   %{
     ...>     "data" => [
     ...>       %{
     ...>         "attributes" => %{
     ...>           "text" => "First Post!"
     ...>         },
     ...>         "id" => "1",
     ...>         "relationships" => %{
     ...>           "comments" => %{
     ...>             "data" => [
     ...>               %{
     ...>                 "id" => "1",
     ...>                 "type" => "comment"
     ...>               }
     ...>             ]
     ...>           }
     ...>         },
     ...>         "type" => "post"
     ...>       }
     ...>     ]
     ...>   },
     ...>   %Alembic.Error{
     ...>     meta: %{
     ...>       "action" => :create,
     ...>       "sender" => :client
     ...>     },
     ...>     source: %Alembic.Source{
     ...>       pointer: ""
     ...>     }
     ...>   }
     ...> )
     {
       :ok,
       %Alembic.Document{
         data: [
           %Alembic.Resource{
             attributes: %{
               "text" => "First Post!"
             },
             id: "1",
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
     }

  With `"relationships"`, a resources collection can optionally have `"included"` for the attributes for the resource
  identifiers.  If `"included"` is not given or the `"id"` and `"type"` for a resource identifier, then the resource
  identifier should just be considered a foreign key reference that needs to be fetched with another API query.

     iex> Alembic.Document.from_json(
     ...>   %{
     ...>     "data" => [
     ...>       %{
     ...>         "attributes" => %{
     ...>           "text" => "First Post!"
     ...>         },
     ...>         "id" => "1",
     ...>         "relationships" => %{
     ...>           "comments" => %{
     ...>             "data" => [
     ...>               %{
     ...>                 "id" => "1",
     ...>                 "type" => "comment"
     ...>               }
     ...>             ]
     ...>           }
     ...>         },
     ...>         "type" => "post"
     ...>       }
     ...>     ],
     ...>     "included" => [
     ...>       %{
     ...>         "attributes" => %{
     ...>           "text" => "First Comment!"
     ...>         },
     ...>         "id" => "1",
     ...>         "type" => "comment"
     ...>       }
     ...>     ]
     ...>   },
     ...>   %Alembic.Error{
     ...>     meta: %{
     ...>       "action" => :create,
     ...>       "sender" => :client
     ...>     },
     ...>     source: %Alembic.Source{
     ...>       pointer: ""
     ...>     }
     ...>   }
     ...> )
     {
       :ok,
       %Alembic.Document{
         data: [
           %Alembic.Resource{
             attributes: %{
               "text" => "First Post!"
             },
             id: "1",
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
         ],
         included: [
           %Alembic.Resource{
             attributes: %{
               "text" => "First Comment!"
             },
             id: "1",
             type: "comment"
           }
         ]
       }
     }

  #### Resource Identifiers

  Or a list of resource identifiers

      iex> Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => [
      ...>       %{
      ...>         "id" => "1",
      ...>         "type" => "post"
      ...>       }
      ...>     ]
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          data: [
            %Alembic.ResourceIdentifier{
              id: "1",
              type: "post"
            }
          ]
        }
      }

  #### Empty

  An empty collection can be signified with `[]`.  Because there is no type information, it's not possible to tell
  whether it is an empty list of `Alembic.Resource.t` or `Alembic.ResourceIdentifier.t`.

      iex> Alembic.Document.from_json(
      ...>   %{
      ...>     "data" => []
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          data: []
        }
      }

  ## Errors documents

  Errors from the sender must have an `"errors"` key set to a list of errors.

      iex> Alembic.Document.from_json(
      ...>   %{
      ...>     "errors" => [
      ...>       %{
      ...>         "code" => "1",
      ...>         "detail" => "There was an error in data",
      ...>         "id" => "2",
      ...>         "links" => %{
      ...>           "about" => %{
      ...>             "href" => "/errors/2",
      ...>             "meta" => %{
      ...>               "extra" => "about meta"
      ...>             }
      ...>           }
      ...>         },
      ...>         "meta" => %{
      ...>           "extra" => "error meta"
      ...>         },
      ...>         "source" => %{
      ...>           "pointer" => "/data"
      ...>         },
      ...>         "status" => "422",
      ...>         "title" => "There was an error"
      ...>       }
      ...>     ]
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              code: "1",
              detail: "There was an error in data",
              id: "2",
              links: %{
                "about" => %Alembic.Link{
                  href: "/errors/2",
                  meta: %{
                    "extra" => "about meta"
                  }
                }
              },
              meta: %{
                "extra" => "error meta"
              },
              source: %Alembic.Source{
                pointer: "/data"
              },
              status: "422",
              title: "There was an error"
            }
          ]
        }
      }

  Error objects **MUST** be returned as an *array* keyed by `"errors"` in the top level of a JSON API document.

      iex> Alembic.Document.from_json(
      ...>   %{"errors" => "Lots of errors"},
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/errors` type is not array",
              meta: %{
                "type" => "array"
              },
              source: %Alembic.Source{
                pointer: "/errors"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ## Meta documents

  Returned documents can contain just `"meta"` with neither `"data"` nor `"errors"`

      iex> Alembic.Document.from_json(
      ...>   %{
      ...>     "meta" => %{
      ...>       "copyright" => "2016"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Document{
          meta: %{
            "copyright" => "2016"
          }
        }
      }

  ## Incomplete documents

  If neither `"errors"`, `"data"`, nor `"meta"` is present, then the document is invalid and a `Alembic.

      iex> Alembic.Document.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     meta: %{
      ...>       "action" => :create,
      ...>       "sender" => :server
      ...>     },
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "At least one of the following children of `` must be present:\\n" <>
                      "data\\n" <>
                      "errors\\n" <>
                      "meta",
              meta: %{
                "children" => [
                  "data",
                  "errors",
                  "meta"
                ]
              },
              source: %Alembic.Source{
                pointer: ""
              },
              status: "422",
              title: "Not enough children"
            }
          ],
        }
      }

  """
  def from_json(json, error_template)

  def from_json(json = %{}, error_template) do
    parent = %{error_template: error_template, json: json}

    child_options_list
    |> Stream.map(&Map.put(&1, :parent, parent))
    |> Stream.map(&FromJson.from_parent_json_to_field_result/1)
    |> FromJson.reduce({:ok, %__MODULE__{}})
    |> validate_minimum_children(json, error_template)
  end

  def from_json(_, error_template) do
    {
      :error,
      %__MODULE__{
        errors: [
          Error.type(error_template, @human_type)
        ]
      }
    }
  end

  @doc """
  Merges the errors from two documents together.

  The errors from the second document are prepended to the errors of the first document so that the errors as a whole
  can be reversed with `reverse/1`
  """
  def merge(first, second)

  @spec merge(%__MODULE__{errors: [Error.t]}, %__MODULE__{errors: [Error.t]}) :: %__MODULE__{errors: [Error.t]}
  def merge(%__MODULE__{errors: first_errors}, %__MODULE__{errors: second_errors}) when is_list(first_errors) and
                                                                                        is_list(second_errors) do
    %__MODULE__{
      # Don't use Enum.into as it will reverse the list immediately, which is more reversing that necessary since
      # merge is called a bunch of time in sequence.
      errors: Enum.reduce(second_errors, first_errors, fn (second_error, acc_errors) ->
        [second_error | acc_errors]
      end)
    }
  end

  @doc """
  Since `merge/2` adds the second `errors` to the beginning of a `first` document's `errors` list, the final merged
  `errors` needs to be reversed to maintain the original order.

      iex> merged = %Alembic.Document{
      ...>   errors: [
      ...>     %Alembic.Error{
      ...>       detail: "The index `2` of `/data` is not a resource",
      ...>       source: %Alembic.Source{
      ...>         pointer: "/data/2"
      ...>       },
      ...>       title: "Element is not a resource"
      ...>     },
      ...>     %Alembic.Error{
      ...>       detail: "The index `1` of `/data` is not a resource",
      ...>       source: %Alembic.Source{
      ...>         pointer: "/data/1"
      ...>       },
      ...>       title: "Element is not a resource"
      ...>     }
      ...>   ]
      ...> }
      iex> Alembic.Document.reverse(merged)
      %Alembic.Document{
        errors: [
          %Alembic.Error{
            detail: "The index `1` of `/data` is not a resource",
            source: %Alembic.Source{
              pointer: "/data/1"
            },
            title: "Element is not a resource"
          },
          %Alembic.Error{
            detail: "The index `2` of `/data` is not a resource",
            source: %Alembic.Source{
              pointer: "/data/2"
            },
            title: "Element is not a resource"
          }
        ]
      }

  """
  def reverse(document = %__MODULE__{errors: errors}) when is_list(errors) do
    %__MODULE__{document | errors: Enum.reverse(errors)}
  end

  ## Private functions

  @spec child_options_list :: [map, ...]
  defp child_options_list do
    [errors_options, included_options | @child_options_list]
  end

  @spec errors_options :: map
  defp errors_options do
    put_in @errors_options[:member][:from_json], &FromJson.from_json_array(&1, &2, Error)
  end

  @spec included_options :: map
  defp included_options do
    put_in @included_options[:member][:from_json], &FromJson.from_json_array(&1, &2, Resource)
  end

  # Whether `json` has at least one of `"data"`, `"errors"`, `"meta"`
  @spec minimum_children?(Alembic.json_object) :: boolean
  defp minimum_children?(json), do: Enum.any? @minimum_children, &Map.has_key?(json, &1)

  @spec minimum_children_error(Error.t) :: FromJson.error
  defp minimum_children_error(error_template) do
    {
      :error,
      %__MODULE__{
        errors: [
          Error.minimum_children(error_template, @minimum_children)
        ]
      }
    }
  end

  @spec validate_minimum_children({:ok, t}, Alembic.json_object, Error.t) :: {:ok, t} | FromJson.error
  @spec validate_minimum_children({:error, t}, Alembic.json_object, Error.t) :: FromJson.error
  defp validate_minimum_children(collectable_result, json, error_template) do
    if minimum_children?(json) do
      collectable_result
    else
      FromJson.merge(collectable_result, minimum_children_error(error_template))
    end
  end

  # Protocol Implementations

  defimpl Poison.Encoder do
    alias Alembic.Document

    @doc """
    ## Data

    A `nil` data is preserved as `"data": null` in JSON API represents an empty single resource as long as there aren't
    `errors`.

        iex> Poison.encode(
        ...>   %Alembic.Document{
        ...>     data: nil
        ...>   }
        ...> )
        {:ok, "{\\"data\\":null}"}

    ## Errors

    When there are `errors`, a `nil` `data` is not encoded as `errors` are exclusive from `data`

        iex> Poison.encode(
        ...>   %Alembic.Document{
        ...>     data: nil,
        ...>     errors: [
        ...>       %Alembic.Error{
        ...>         source: %Alembic.Source{
        ...>           pointer: ""
        ...>         }
        ...>       }
        ...>     ]
        ...>   }
        ...> )
        {:ok, "{\\"errors\\":[{\\"source\\":{\\"pointer\\":\\"\\"}}],\\"data\\":null}"}

    ## Meta

    Since `"meta"` can be sent with either `"data"` or `"errors"` and `"data"` can be `nil` for empty single resource,
    to get an encoding with only `"meta"`, you need to use an option: `drop: [:data]`.

        iex> Poison.encode(
        ...>   %Alembic.Document{
        ...>     data: nil,
        ...>     meta: %{
        ...>       "copyright" => "2016"
        ...>     }
        ...>   },
        ...>   drop: [:data]
        ...> )
        {:ok, "{\\"meta\\":{\\"copyright\\":\\"2016\\"}}"}

    ## Invalid

    `"data"` and `"errors"` cannot exist in the same JSON API document, so they will fail to encode

        iex> try do
        ...>   Poison.encode(
        ...>     %Alembic.Document{
        ...>       data: [],
        ...>       errors: [
        ...>         %Alembic.Error{
        ...>           source: %Alembic.Source{
        ...>             pointer: ""
        ...>           }
        ...>         }
        ...>       ]
        ...>     }
        ...>   )
        ...> rescue
        ...>   e in ArgumentError -> e
        ...> end
        %ArgumentError{
           message: "`data` and `errors` is exclusive in JSON API, but both are set: data is `[]` and errors is " <>
                    "`[%Alembic.Error{code: nil, detail: nil, id: nil, links: nil, meta: nil, " <>
                    "source: %Alembic.Source{parameter: nil, pointer: \\"\\"}, " <>
                    "status: nil, title: nil}]`"
        }

    """

    def encode(%Document{data: data, errors: errors}, _) when not is_nil(data) and not is_nil(errors) do
      raise ArgumentError,
            "`data` and `errors` is exclusive in JSON API, but both are set: data is `#{inspect data}` and errors " <>
            "is `#{inspect errors}`"
    end

    def encode(document = %Document{}, options) do
      # `data: nil` is allowed to be encoded as `"data": null` because `null` `"data"` is an empty single resource
      map = for {field, value} <- Map.from_struct(document),
                field == :data || value != nil,
                into: %{},
                do: {field, value}

      drop = Keyword.get(options, :drop, [])
      map = Map.drop(map, drop)

      Poison.Encoder.Map.encode(map, options)
    end
  end
end
