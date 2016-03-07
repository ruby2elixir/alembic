defmodule Alembic.Fetch do
  @moduledoc """
  [Fetching Data](http://jsonapi.org/format/#fetching) in the JSON API spec
  """

  alias __MODULE__.Includes

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
end
