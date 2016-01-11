defmodule Alembic.ResourceIdentifier do
  @moduledoc """
  A [JSON API Resource Identifier](http://jsonapi.org/format/#document-resource-identifier-objects).
  """

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.Meta

  @behaviour FromJson

  # Constants

  @human_type "resource identifier"

  @meta_options %{
                  field: :meta,
                  member: %{
                    module: Meta,
                    name: "meta"
                  },
                  parent: nil
                }

  # Struct

  defstruct [:id, :meta, :type]

  # Types

  @typedoc """
  > A "resource identifier object" is \\[an `%Alembic.ResourceIdentifier{}`\\] that identifies an
  > individual resource.
  >
  > A "resource identifier object" **MUST** contain `type` and `id` members.
  >
  > A "resource identifier object" **MAY** also include a `meta` member, whose value is a
  > \\[`Alembic.Meta.t`\\] that contains non-standard meta-information.
  >
  > -- <cite>
  >  [JSON API - Document Structure - Resource Identifier
  >   Object](http://jsonapi.org/format/#document-resource-identifier-objects)
  > </cite>
  """
  @type t :: %__MODULE__{
               id: String.t,
               meta: Meta.t,
               type: String.t
             }

  # Functions

  @doc """
  # Examples

  ## A resource identifier is valid with `"id"` and `"type"`

      iex> Alembic.ResourceIdentifier.from_json(
      ...>   %{"id" => "1", "type" => "shirt"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/shirt/data"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.ResourceIdentifier{id: "1", type: "shirt"}}

  ## A resource identifier can *optionally* have `"meta"`

      iex> Alembic.ResourceIdentifier.from_json(
      ...>   %{"id" => "1", "meta" => %{"copyright" => "2015"}, "type" => "shirt"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/shirt/data"
      ...>     }
      ...>   }
      ...> )
      {:ok, %Alembic.ResourceIdentifier{id: "1", meta: %{"copyright" => "2015"}, type: "shirt"}}

  ## A resource identifier **MUST** have an `"id"`

      iex> Alembic.ResourceIdentifier.from_json(
      ...>   %{"type" => "shirt"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/shirt/data"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
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

  ## A resource identifer **MUST** have a `"type"`

      iex> Alembic.ResourceIdentifier.from_json(
      ...>   %{"id" => "1"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/shirt/data"
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
            }
          ]
        }
      }

  ## A resource identifer missing both `"id"` and `"type"` will show both as missing

      iex> Alembic.ResourceIdentifier.from_json(
      ...>   %{},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/shirt/data"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
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
            },
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
            }
          ]
        }
      }

  ## A non-resource-identifier will be identified as such

      iex> Alembic.ResourceIdentifier.from_json(
      ...>   [],
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/data/relationships/shirt/data"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/shirt/data` type is not resource identifier",
              meta: %{
                "type" => "resource identifier"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/shirt/data"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  """
  def from_json(json, error_template)

  @spec from_json(%{String.t => String.t | Alembic.json_object}, Error.t) :: {:ok, t} | FromJson.error
  def from_json(json = %{}, error_template = %Error{}) do
    parent = %{json: json, error_template: error_template}

    id_result = FromJson.from_parent_json_to_field_result %{
      field: :id,
      member: %{
        from_json: &FromJson.string_from_json/2,
        name: "id",
        required: true,
      },
      parent: parent
    }

    meta_result = FromJson.from_parent_json_to_field_result %{@meta_options | parent: parent}

    type_result = FromJson.from_parent_json_to_field_result %{
      field: :type,
      member: %{
        from_json: &FromJson.string_from_json/2,
        name: "type",
        required: true
      },
      parent: parent
    }

    FromJson.reduce([id_result, meta_result, type_result], {:ok, %__MODULE__{}})
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
end
