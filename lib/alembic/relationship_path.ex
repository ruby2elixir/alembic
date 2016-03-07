defmodule Alembic.RelationshipPath do
  @moduledoc """
  > A relationship path is a dot-separated (U+002E FULL-STOP, ".") list of relationship names.
  >
  > -- [JSON API > Fetching Data > Inclusion Of Related Resources](http://jsonapi.org/format/#fetching-includes)
  """

  alias Alembic.Fetch.Includes

  # Constants

  @relationship_name_separator "."

  # Types

  @typedoc """
  **NOTE: Kept as a string until application can validate relationship name.**

  The name of a relationship.
  """
  @type relationship_name :: String.t

  @typedoc """
  > A relationship path is a dot-separated (U+002E FULL-STOP, ".") list of relationship names.
  >
  > -- [JSON API > Fetching Data > Inclusion Of Related Resources](http://jsonapi.org/format/#fetching-includes)
  """
  @type t :: String.t

  # Functions

  @doc """
  Breaks the `relationship_path` into `relationship_name`s in a nested map to form
  `Alembic.Fetch.Include.include`

  A relationship name passes through unchanged

      iex> Alembic.RelationshipPath.to_include("comments")
      "comments"

  A relationship path becomes a (nested) map

      iex> Alembic.RelationshipPath.to_include("comments.author.posts")
      %{
        "comments" => %{
          "author" => "posts"
        }
      }

  """
  @spec to_include(t) :: Includes.include
  def to_include(relationship_path) do
    relationship_path
    |> String.split(@relationship_name_separator)
    |> Enum.reverse
    |> Enum.reduce(fn (relationship_name, include) ->
         %{relationship_name => include}
       end)
  end
end
