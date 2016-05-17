defmodule Alembic.Document do
  @moduledoc """
  JSON API refers to the top-level JSON structure as a [document](http://jsonapi.org/format/#document-structure).
  """

  alias Alembic.Error
  alias Alembic.FromJson

  # Behaviours

  @behaviour FromJson

  # Struct

  defstruct errors: nil

  # Types

  @typedoc """
  A JSON API [Document](http://jsonapi.org/format/#document-structure).

  ## Errors

  When an error occurs, only `errors` are returned in the document.
  """
  @type t :: %__MODULE__{
               errors: [Error.t],
             }

  # Functions

  @doc """
  Converts a JSON object into a JSON API Document, `t`.

  ## Error documents

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

  If `"errors"` isn't even present, it will be a different error.

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
              detail: "`/errors` is missing",
              meta: %{
                "child" => "errors"
              },
              source: %Alembic.Source{
                pointer: ""
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  """
  def from_json(json, error_template)

  def from_json(%{"errors" => errors}, error_template = %Error{}) do
    field_result = errors
                   |> FromJson.from_json_array(Error.descend(error_template, "errors"), Error)
                   |> FromJson.put_key(:errors)

    FromJson.merge({:ok, %__MODULE__{}}, field_result)
  end

  def from_json(%{}, error_template = %Error{}) do
    {
      :error,
      %__MODULE__{
        errors: [
          Error.missing(error_template, "errors")
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
  def merge(%__MODULE__{errors: first_errors}, %__MODULE__{errors: second_errors})
      when is_list(first_errors) and is_list(second_errors) do
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
end
