defmodule Alembic.Fetch.Includes do
  @moduledoc """
  [Fetching Data > Inclusion of Related Resources](http://jsonapi.org/format/#fetching-includes)
  """

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson
  alias Alembic.RelationshipPath
  alias Ecto.Query

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

  @type preload :: term

  @type preload_by_include :: %{include => preload}

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

  @doc """
  Converts a String-based include that uses relationship names to Atom-based association names used in a preload

  ## Relationship Name

  A relationship name is looked up in `preload_by_include`

      iex> Alembic.Fetch.Includes.to_preload(
      ...>   "comments",
      ...>   %{
      ...>     "comments" => :comments
      ...>   }
      ...> )
      {:ok, :comments}

  A relationship name not found in `preload_by_include` will generate a JSON API errors Document with an error on the
  "include" parameter

      iex> Alembic.Fetch.Includes.to_preload(
      ...>   "secret",
      ...>   %{}
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`secret` is an unknown relationship path",
              meta: %{
                "relationship_path" => "secret"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            }
          ]
        }
      }

  ## Relationship Path

  A relationship path is looked up in `preload_by_include` directly, and **NOT** recursively, so the key itself needs to
  be an `include`

      iex> Alembic.Fetch.Includes.to_preload(
      ...>   %{
      ...>     "comments" => "author"
      ...>   },
      ...>   %{
      ...>     %{
      ...>       "comments" => "author"
      ...>     } => [comments: :author]
      ...>   }
      ...> )
      {:ok, [comments: :author]}

  A relationship path not found in `preload_by_include` will generate a JSON API errors Document with an error on the
  "include" parameter

      iex> Alembic.Fetch.Includes.to_preload(
      ...>   %{
      ...>     "secret" => "super-secret"
      ...>   },
      ...>   %{}
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`secret.super-secret` is an unknown relationship path",
              meta: %{
                "relationship_path" => "secret.super-secret"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            }
          ]
        }
      }

  """
  @spec to_preload(include, preload_by_include) :: {:ok, term} | {:error, Document.t}
  def to_preload(include, preload_by_include) do
    case Map.fetch(preload_by_include, include) do
      {:ok, preload} ->
        {:ok, preload}
      :error ->
        error = include
                |> to_relationship_path
                |> Error.relationship_path

        {
          :error,
          %Document{
            errors: [error]
          }
        }
    end
  end

  @doc """
  Converts the String-based includes that use relationship names to Atom-based association names used in preloads

  With no includes, there will be no preloads, and so the conversion map doesn't matter

      iex> Alembic.Fetch.Includes.to_preloads([], %{})
      {:ok, []}

  ## Relationship names

  Relationship names are looked up in `preload_by_include`

      iex> Alembic.Fetch.Includes.to_preloads(
      ...>   ~w{comments links},
      ...>   %{
      ...>     "comments" => :comments,
      ...>      "links" => :links
      ...>   }
      ...> )
      {
        :ok,
        [
          :comments,
          :links
        ]
      }

  Relationship names that are not found in `preload_by_include` will return a merged JSON API errors document. The error
  document will hide any includes that could be found.

      iex> Alembic.Fetch.Includes.to_preloads(
      ...>   ~w{secret comments hidden links},
      ...>   %{
      ...>      "comments" => :comments,
      ...>      "links" => :links
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`secret` is an unknown relationship path",
              meta: %{
                "relationship_path" => "secret"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            },
            %Alembic.Error{
              detail: "`hidden` is an unknown relationship path",
              meta: %{
                "relationship_path" => "hidden"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            }
          ]
        }
      }

  ## Relationship Paths

  Relationship paths are a looked up in `preload_by_include` directly, and **NOT** recursively, so the key itself needs
  to be an `include`

      iex> Alembic.Fetch.Includes.to_preloads(
      ...>   [
      ...>     %{ "comments" => "author" },
      ...>     %{ "links" => "clickers" }
      ...>   ],
      ...>   %{
      ...>     %{ "comments" => "author" } => [comments: :author],
      ...>     %{ "links" => "clickers" } => [links: :clickers]
      ...>   }
      ...> )
      {
        :ok,
        [
          [comments: :author],
          [links: :clickers]
        ]
      }

  Relationship paths that are not found in `preload_by_include` will return a merged JSON API errors document. The error
  document wil hide any includes that could be found.

      iex> Alembic.Fetch.Includes.to_preloads(
      ...>   [
      ...>     %{ "comments" => "secret" },
      ...>     %{ "comments" => "author" },
      ...>     %{ "links" => "hidden" },
      ...>     %{ "links" => "clickers" }
      ...>   ],
      ...>   %{
      ...>     %{ "comments" => "author" } => [comments: :author],
      ...>     %{ "links" => "clickers" } => [links: :clickers]
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`comments.secret` is an unknown relationship path",
              meta: %{
                "relationship_path" => "comments.secret"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            },
            %Alembic.Error{
              detail: "`links.hidden` is an unknown relationship path",
              meta: %{
                "relationship_path" => "links.hidden"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            }
          ]
        }
      }

  """
  @spec to_preloads(t, preload_by_include) :: {:ok, list} | {:error, Document.t}
  def to_preloads(includes, preload_by_include) do
    includes
    |> Stream.map(&to_preload(&1, preload_by_include))
    |> FromJson.reduce({:ok, []})
  end

  @doc """
  Add preloads for `includes` to `query`.

  If there are no includes, then the `query` is returns unchanged.

      iex> require Ecto.Query
      iex> query = Ecto.Query.from p in Alembic.TestPost
      %Ecto.Query{
        from: {"posts", Alembic.TestPost}
      }
      iex> {:ok, query_with_includes} = Alembic.Fetch.Includes.to_query(
      ...>   [],
      ...>   %{},
      ...>   query
      ...> )
      {
        :ok,
        %Ecto.Query{
          from: {"posts", Alembic.TestPost}
        }
      }
      iex> query_with_includes == query
      true

  If there are includes, they are converted to preloads and added to the `query`

      iex> require Ecto.Query
      iex> query = Ecto.Query.from p in Alembic.TestPost
      %Ecto.Query{
        from: {"posts", Alembic.TestPost}
      }
      iex> Alembic.Fetch.Includes.to_query(
      ...>   ["comments"],
      ...>   %{
      ...>     "comments" => :comments
      ...>   },
      ...>   query
      ...> )
      {
        :ok,
        %Ecto.Query{
          from: {"posts", Alembic.TestPost},
          preloads: [[:comments]]
        }
      }

  If the includes can't be converted to preloads, then the conversion errors are returned

      iex> require Ecto.Query
      iex> query = Ecto.Query.from p in Alembic.TestPost
      %Ecto.Query{
        from: {"posts", Alembic.TestPost}
      }
      iex> Alembic.Fetch.Includes.to_query(
      ...>   ["secret"],
      ...>   %{},
      ...>   query
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`secret` is an unknown relationship path",
              meta: %{
                "relationship_path" => "secret"
              },
              source: %Alembic.Source{
                parameter: "include"
              },
              title: "Unknown relationship path"
            }
          ]
        }
      }

  """
  @spec to_query(t, preload_by_include, Query.t) :: {:ok, Query.t} | {:error, Document.t}
  def to_query(includes, preload_by_include, query) do
    with {:ok, preloads} <- to_preloads(includes, preload_by_include) do
      {:ok, preloads_to_query(preloads, query)}
    end
  end

  @doc """
  Converts an `include` back to relationship path
  """
  @spec to_relationship_path(include) :: RelationshipPath.t
  def to_relationship_path(include) do
    include
    |> to_relationship_path([])
  end

  ## Private Functions

  defp preloads_to_query(preloads = [_], query) do
    require Query
    Query.preload(query, ^preloads)
  end

  defp preloads_to_query(_, query), do: query

  defp to_relationship_path(relationship_name, relationship_names) when is_binary(relationship_name) do
    [relationship_name | relationship_names]
    |> Enum.reverse
    |> Enum.join(RelationshipPath.relationship_name_separator)
  end

  defp to_relationship_path(include, relationship_names) when is_map(include) and map_size(include) == 1 do
    [relationship_name] = Map.keys include
    descendant_include = include[relationship_name]
    to_relationship_path(descendant_include, [relationship_name | relationship_names])
  end
end
