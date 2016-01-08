defmodule Alembic.Error do
  @moduledoc """
  [Error objects](http://jsonapi.org/format/#error-objects) provide additional information about problems encountered
  while performing an operation. Error objects **MUST** be returned as an array keyed by `errors` in the top level of a
  JSON API document.
  """

  alias Alembic.FromJson
  alias Alembic.Links
  alias Alembic.Meta
  alias Alembic.Source

  # Behaviours

  @behaviour FromJson

  # Constants

  @code_options %{
                  field: :code,
                  member: %{
                    from_json: &FromJson.string_from_json/2,
                    name: "code"
                  },
                }

  @detail_options %{
                    field: :detail,
                    member: %{
                      from_json: &FromJson.string_from_json/2,
                      name: "detail"
                    },
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

  @source_options %{
                    field: :source,
                    member: %{
                      module: Source,
                      name: "source"
                    }
                  }

  @status_options %{
                    field: :status,
                    member: %{
                      from_json: &FromJson.string_from_json/2,
                      name: "status"
                    }
                  }

  @title_options %{
                   field: :title,
                   member: %{
                     from_json: &FromJson.string_from_json/2,
                     name: "title"
                   }
                 }

  @child_options_list [
    @code_options,
    @detail_options,
    @id_options,
    @links_options,
    @meta_options,
    @source_options,
    @status_options,
    @title_options
  ]

  # Struct

  defstruct code: nil,
            detail: nil,
            id: nil,
            links: nil,
            meta: nil,
            source: nil,
            status: nil,
            title: nil

  # Types

  @typedoc """
  The name of a JSON type in human-readable terms, such as `"array"` or `"object"`.
  """
  @type human_type :: String.t

  @typedoc """
  Additional information about problems encountered while performing an operation.

  An error object **MAY** have the following members:

  * `code` - an application-specific error code.
  * `detail` - a human-readable explanation specific to this occurrence of the problem.
  * `id` - a unique identifier for this particular occurrence of the problem.
  * `links` - contains the following members:
      * `"about"` - an `Alembic.Link.link` leading to further details about this particular occurrence of the problem.
  * `meta` - non-standard meta-information about the error.
  * `source` - contains references to the source of the error, optionally including any of the following members:
  * `status` - the HTTP status code applicable to this problem.
  * `title` - a short, human-readable summary of the problem that **SHOULD NOT** change from occurrence to occurrence of
    the problem, except for purposes of localization.
  """
  @type t :: %__MODULE__{
               code: String.t,
               detail: String.t,
               id: String.t,
               links: Links.t,
               meta: Meta.t,
               source: Source.t,
               status: String.t,
               title: String.t
             }

  @doc """
  Descends `source` `pointer` to `child` of current `source` `pointer`

      iex> Alembic.Error.descend(
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   },
      ...>   1
      ...> )
      %Alembic.Error{
        source: %Alembic.Source{
          pointer: "/data/1"
        }
      }

  """
  @spec descend(t, String.t | integer) :: t
  def descend(error = %__MODULE__{source: source}, child) do
    %__MODULE__{error | source: Source.descend(source, child)}
  end

  @doc """
  Converts a JSON object into a JSON API Error, `t`.

      iex> Alembic.Error.from_json(
      ...>   %{
      ...>     "code" => "1",
      ...>     "detail" => "There was an error in data",
      ...>     "id" => "2",
      ...>     "links" => %{
      ...>       "about" => %{
      ...>         "href" => "/errors/2",
      ...>         "meta" => %{
      ...>           "extra" => "about meta"
      ...>         }
      ...>       }
      ...>     },
      ...>     "meta" => %{
      ...>       "extra" => "error meta"
      ...>     },
      ...>     "source" => %{
      ...>       "pointer" => "/data"
      ...>     },
      ...>     "status" => "422",
      ...>     "title" => "There was an error"
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
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
      }

  """
  def from_json(json_object = %{}, template = %__MODULE__{}) do
    parent = %{json: json_object, error_template: template}

    @child_options_list
    |> Stream.map(&Map.put(&1, :parent, parent))
    |> Stream.map(&FromJson.from_parent_json_to_field_result/1)
    |> FromJson.reduce({:ok, %__MODULE__{}})
  end

  @doc """
  When two or more members can't be present at the same time.

      iex> Alembic.Error.conflicting(
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/source"
      ...>     }
      ...>   },
      ...>   ~w{parameter pointer}
      ...> )
      %Alembic.Error{
        detail: "The following members conflict with each other (only one can be present):\\nparameter\\npointer",
        meta: %{
          "children" => [
            "parameter",
            "pointer"
          ]
        },
        source: %Alembic.Source{
          pointer: "/errors/0/source"
        },
        status: "422",
        title: "Children conflicting"
      }

  """
  @spec conflicting(t, [String.t]) :: t
  def conflicting(template, children)

  def conflicting(%__MODULE__{source: source}, children) when is_list(children) do
    %__MODULE__{
      detail: "The following members conflict with each other (only one can be present):\n" <>
              Enum.join(children, "\n"),
      meta: %{
        "children" => children
      },
      source: source,
      status: "422",
      title: "Children conflicting"
    }
  end

  @doc """
  When a required (**MUST** in the spec) member is missing

  # Top-level member is missing

      iex> Alembic.Error.missing(
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: ""
      ...>     }
      ...>   },
      ...>   "data"
      ...> )
      %Alembic.Error{
        detail: "`/data` is missing",
        meta: %{
          "child" => "data"
        },
        source: %Alembic.Source{
          pointer: ""
        },
        status: "422",
        title: "Child missing"
      }

  # Nested member is missing

      iex> Alembic.Error.missing(
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data"
      ...>     }
      ...>   },
      ...>   "type"
      ...> )
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

  """
  @spec missing(t, String.t) :: t
  def missing(template, child)

  def missing(%__MODULE__{source: source = %Source{pointer: parent_pointer}}, child) do
    %__MODULE__{
      detail: "`#{parent_pointer}/#{child}` is missing",
      meta: %{
        "child" => child
      },
      source: source,
      status: "422",
      title: "Child missing"
    }
  end

  @doc """
  Error when the JSON type of the field is wrong.

  **NOTE: The *JSON* type should be used, not the Elixir/Erlang type, so if a member is not a `map` in Elixir, the
  `human_type` should be `"object"`.  Likewise, if a member is not a `list` in Elixir, the `human_type` should be
  `"array"`.**

  # When member is not an Elixir `list` or JSON array

      iex> validate_errors = fn
      ...>   (list) when is_list(list) ->
      ...>     {:ok, list}
      ...>   (_) ->
      ...>     {
      ...>       :error,
      ...>       Alembic.Error.type(
      ...>         %Alembic.Error{
      ...>           source: %Alembic.Source{
      ...>             pointer: "/errors"
      ...>           }
      ...>         },
      ...>         "array"
      ...>       )
      ...>     }
      ...> end
      iex> json = %{"errors" => "invalid"}
      iex> validate_errors.(json["errors"])
      {
        :error,
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
      }

  # When member is not an Elixir `map` or JSON object

      iex> validate_meta = fn
      ...>   (meta) when is_map(meta) ->
      ...>     {:ok, meta}
      ...>   (_) ->
      ...>     {
      ...>       :error,
      ...>       Alembic.Error.type(
      ...>         %Alembic.Error{
      ...>           source: %Alembic.Source{
      ...>             pointer: "/meta"
      ...>           }
      ...>         },
      ...>         "object"
      ...>       )
      ...>     }
      ...> end
      iex> json = %{"meta" => "invalid"}
      iex> validate_meta.(json["meta"])
      {
        :error,
        %Alembic.Error{
          detail: "`/meta` type is not object",
          meta: %{
            "type" => "object"
          },
          source: %Alembic.Source{
            pointer: "/meta"
          },
          status: "422",
          title: "Type is wrong"
        }
      }
  """
  @spec type(t, human_type) :: t
  def type(%__MODULE__{source: source = %Source{pointer: pointer}}, human_type) do
    %__MODULE__{
      detail: "`#{pointer}` type is not #{human_type}",
      meta: %{
        "type" => human_type
      },
      source: source,
      status: "422",
      title: "Type is wrong"
    }
  end
end
