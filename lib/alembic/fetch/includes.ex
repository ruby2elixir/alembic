defmodule Alembic.Fetch.Includes do
  @moduledoc """
  [Fetching Data > Inclusion of Related Resources](http://jsonapi.org/format/#fetching-includes)
  """

  alias Alembic.RelationshipPath

  # Types

  @typedoc """
  A nested `map` of `relationship_name`s
  """
  @type include :: RelationshipPath.relationship_name |
                   %{RelationshipPath.relationship_name => include}

  @typedoc """
  A list of `include`s
  """
  @type t :: [include]

  @type params :: %{}

  # Functions

  @doc """
  Extract `t` from `"include"` in `params

  `params` without `"include"` will have no includes

      iex> Alembic.Fetch.Includes.from_params(%{})
      []

  `params` with `"include"` will have the value of `"includes"` broken into `t`

      iex> Alembic.Fetch.Includes.from_params(
      ...>   %{
      ...>     "include" => "author,comments.author.posts"
      ...>   }
      ...> )
      [
        "author",
        %{
          "comments" => %{
            "author" => "posts"
          }
        }
      ]

  """
  @spec from_params(params) :: [include]
  def from_params(params) when is_map(params) do
    case Map.fetch(params, "include") do
      :error ->
        []
      {:ok, include} ->
        from_string(include)
    end
  end

  @doc """
  Breaks the `relationship_path` into `relationship_name`s in a nested map to form multiple includes

  An empty String will have no includes

      iex> Alembic.Fetch.Includes.from_string("")
      []

  A single relationship name will become the only include

      iex> Alembic.Fetch.Includes.from_string("comments")
      ["comments"]

  A relationship path will become the only include

      iex> Alembic.Fetch.Includes.from_string("comments.author.posts")
      [
        %{
          "comments" => %{
            "author" => "posts"
          }
        }
      ]

  Each relationship name or relationship path will be a separate element in includes

      iex> Alembic.Fetch.Includes.from_string("author,comments.author.posts")
      [
        "author",
        %{
          "comments" => %{
            "author" => "posts"
          }
        }
      ]

  """
  @spec from_string(String.t) :: t
  def from_string(comma_separated_relationship_paths) do
    comma_separated_relationship_paths
    |> String.splitter(",", trim: true)
    |> Enum.map(&RelationshipPath.to_include/1)
  end
end
