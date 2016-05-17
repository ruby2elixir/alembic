defmodule Alembic.Meta do
  @moduledoc """
  > Where specified, a `meta` member can be used to include non-standard meta-information. The value of each `meta`
  > member **MUST** be an object (a "meta object").
  >
  > -- <cite>
  >  [JSON API - Document Structure - Meta Information](http://jsonapi.org/format/#document-meta)
  > </cite>
  """

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson

  # Behaviours

  @behaviour FromJson

  # Constants

  @human_type "meta object"

  # Types

  @type t :: Alembic.json_object

  # Functions

  @doc """
  Converts raw JSON to a "meta object"

  "meta objects" have no defined fields, so all keys remain unchanged.

      iex> Alembic.Meta.from_json(
      ...>   %{"copyright" => "© 2015"},
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/meta"
      ...>     }
      ...>   }
      ...> )
      {:ok, %{"copyright" => "© 2015"}}

  > The value of each meta member MUST be an object (a “meta object”).
  >
  > -- <cite>
  >  [JSON API - Document Structure - Meta Information](http://jsonapi.org/format/#document-meta)
  > </cite>

      iex> Alembic.Meta.from_json(
      ...>   "© 2015",
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/meta"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/meta` type is not meta object",
              meta: %{
                "type" => "meta object"
              },
              source: %Alembic.Source{
                pointer: "/meta"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  However, `meta` is optional in most locations, so `nil` is also allowed

      iex> Alembic.Meta.from_json(
      ...>   nil,
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/meta"
      ...>     }
      ...>   }
      ...> )
      {:ok, nil}

  """
  def from_json(json, error_template)

  @spec from_json(Alembic.json_object, Error.t) :: {:ok, map}
  @spec from_json(nil, Error.t) :: {:ok, nil}
  def from_json(meta, _) when is_map(meta) or is_nil(meta), do: {:ok, meta}

  # the rest of Alembic.json
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
end
