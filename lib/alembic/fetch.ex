defmodule Alembic.Fetch do
  @moduledoc """
  [Fetching Data](http://jsonapi.org/format/#fetching) in the JSON API spec
  """

  alias Alembic.Document
  alias __MODULE__.Includes
  alias Ecto.Query

  # Struct

  defstruct [:includes]

  # Types

  @typedoc """

  """
  @type params :: %{}

  @typedoc """
  The options when performing a fetch

  * `:include` - The relationships paths to include in the response document
  """
  @type t :: %__MODULE__{
               includes: nil | Includes.t
             }

  # Functions

  @doc """
  Extract a `t` from the params.

  * `include` param is parsed in `includes` of `t`

  `params` without `"include"` will have no includes

      iex> Alembic.Fetch.from_params(%{})
      %Alembic.Fetch{
        includes: []
      }

  `params` with `"include"` will have the value of `"includes"` broken into `Alembic.Fetch.Includes.t`

        iex> Alembic.Fetch.from_params(
        ...>   %{
        ...>     "include" => "author,comments.author.posts"
        ...>   }
        ...> )
        %Alembic.Fetch{
          includes: [
            "author",
            %{
              "comments" => %{
                "author" => "posts"
              }
            }
          ]
        }

  """
  @spec from_params(params) :: t
  def from_params(params) when is_map(params) do
    %__MODULE__{
      includes: Includes.from_params(params)
    }
  end

  @doc """
  Converts the `includes` in `fetch` to `Ecto.Query.preload`s.

  With no includes, no preloads are added

      iex> require Ecto.Query
      iex> query = Ecto.Query.from p in Alembic.TestPost
      %Ecto.Query{
        from: {"posts", Alembic.TestPost}
      }
      iex> params = %{}
      iex> fetch = Alembic.Fetch.from_params(params)
      iex> {:ok, fetch_query} = Alembic.Fetch.to_query(fetch, %{}, query)
      {
        :ok,
        %Ecto.Query{
          from: {"posts", Alembic.TestPost}
        }
      }
      iex> fetch_query == query
      true

  If there are includes, they are converted to preloads and added to the `query`

      iex> require Ecto.Query
      iex> query = Ecto.Query.from p in Alembic.TestPost
      %Ecto.Query{
        from: {"posts", Alembic.TestPost}
      }
      iex> params = %{
      ...>   "include" => "comments"
      ...> }
      iex> fetch = Alembic.Fetch.from_params(params)
      iex> Alembic.Fetch.to_query(
      ...>   fetch,
      ...>   %{
      ...>     "comments" => :comments
      ...>   },
      ...>   query
      ...> )
      {
        :ok,
        %Ecto.Query{
          from: {"posts", Alembic.TestPost},
          preloads: [
            [:comments]
          ]
        }
      }

  If the includes can't be converted to preloads, then the conversion errors are returned

      iex> require Ecto.Query
      iex> query = Ecto.Query.from p in Alembic.TestPost
      %Ecto.Query{
        from: {"posts", Alembic.TestPost}
      }
      iex> params = %{
      ...>   "include" => "secret"
      ...> }
      iex> fetch = Alembic.Fetch.from_params(params)
      iex> Alembic.Fetch.to_query(
      ...>   fetch,
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
  @spec to_query(t, Includes.preload_by_include, Query.t) :: {:ok, Query.t} | {:error, Document.t}
  def to_query(fetch, preload_by_include, query)

  def to_query(%__MODULE__{includes: includes}, preload_by_include, query) do
    Includes.to_query(includes, preload_by_include, query)
  end
end
