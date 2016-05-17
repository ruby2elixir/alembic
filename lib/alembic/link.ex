defmodule Alembic.Link do
  @moduledoc """
  A [link object](http://jsonapi.org/format/#document-links) represents a URL and metadata about it.
  """

  alias Alembic
  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.Meta

  # Behaviours

  @behaviour FromJson

  # Constants

  @human_type "link object"

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  },
                  parent: nil
                }

  # Struct

  defstruct href: nil,
            meta: nil

  # Types

  @typedoc """
  An [link object](http://jsonapi.org/format/#document-links) which can contain the following members:
  * `href` - the link's URL.
  * `meta` - contains non-standard meta-information about the link.
  """
  @type t :: %__MODULE__{
               href: String.t | nil,
               meta: Meta.t | nil
             }

  @typedoc """
  * a `String.t` containing the link's URL.
  * a `t`
  """
  @type link :: String.t | t

  # Functions

  @doc """
  Converts JSON to a `link`.

  A `link` can be a `String.t`, so strings will just pass through.  A `link` can also be a `t`, in which case the JSON
  object is checked for `href`.

  ## Strings

  A string will pass through as simple URLs are allowed.

      iex> url = "http://example.com"
      iex> {:ok, url} == Alembic.Link.from_json(
      ...>   url,
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      true

  ## Objects

  URLs can be annotated using "link objects" with an `"href"` and `"meta"`

      iex> Alembic.Link.from_json(
      ...>   %{
      ...>     "href" => "http://example.com",
      ...>     "meta" => %{
      ...>       "last_updated_on" => "2015-12-21"
      ...>     }
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Link{
          href: "http://example.com",
          meta: %{
            "last_updated_on" => "2015-12-21"
          }
        }
      }

  However, the [JSON API spec](http://jsonapi.org/format/#document-links) only says a "link object" `'can contain'`
  `href` and `meta`, not that it **MUST**, so no members are actually required in a "link object"

      iex> Alembic.Link.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.Link{}}

  The wording does mean that the "link" if not a String must be a JSON object (i.e. an Elixir `map`)

      iex> Alembic.Link.from_json(
      ...>   ["http://example.com"],
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/links/0` type is not link object",
              meta: %{
                "type" => "link object"
              },
              source: %Alembic.Source{
                pointer: "/links/0"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  While `href` is optional, if present, must be a `String.t`

      iex> Alembic.Link.from_json(
      ...>   %{"href" => []},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/links/0/href` type is not string",
              meta: %{
                "type" => "string"
              },
              source: %Alembic.Source{
                pointer: "/links/0/href"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  Likewise, `meta`, if present, must be a JSON object (i.e. an Elixir `map`)

      iex> Alembic.Link.from_json(
      ...>   %{"meta" => "© 2015"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/links/0/meta` type is not meta object",
              meta: %{
                "type" => "meta object"
              },
              source: %Alembic.Source{
                pointer: "/links/0/meta"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  If there are errors in both `href` and `meta`, they will accumulate so all errors can be corrected in a second request

      iex> Alembic.Link.from_json(
      ...>   %{
      ...>     "href" => [],
      ...>     "meta" => "© 2015"
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/links/0"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/links/0/href` type is not string",
              meta: %{
                "type" => "string"
              },
              source: %Alembic.Source{
                pointer: "/links/0/href"
              },
              status: "422",
              title: "Type is wrong"
            },
            %Alembic.Error{
              detail: "`/links/0/meta` type is not meta object",
              meta: %{
                "type" => "meta object"
              },
              source: %Alembic.Source{
                pointer: "/links/0/meta"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  """

  @spec from_json(String.t, Error.t) :: {:ok, String.t}
  def from_json(string, _) when is_binary(string) do
    {:ok, string}
  end

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, t} | FromJson.error
  def from_json(json = %{}, error_template = %Error{}) do
    parent = %{json: json, error_template: error_template}

    href_result = FromJson.from_parent_json_to_field_result %{
      field: :href,
      member: %{
        from_json: &href_from_json/2,
        name: "href"
      },
      parent: parent
    }
    meta_result = FromJson.from_parent_json_to_field_result %{@meta_options | parent: parent}
    results = [href_result, meta_result]

    results
    |> FromJson.reduce({:ok, %__MODULE__{}})
  end

  # Alembic.json -- [Alembic.json_object, String.t]
  @spec from_json(nil | true | false | list | float | integer, Error.t) :: FromJson.error
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

  @spec href_from_json(nil, Error.t) :: {:ok, nil}
  def href_from_json(nil, _), do: {:ok, nil}

  @spec href_from_json(String.t, Error.t) :: {:ok, String.t}
  # Alembic.json -- [nil, String.t]
  @spec href_from_json(true | false | list | float | integer | Alembic.json_object, Error.t) :: FromJson.error
  def href_from_json(href, error_template), do: FromJson.string_from_json(href, error_template)
end
