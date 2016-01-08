defmodule Alembic.Source do
  @moduledoc """
  The `source` of an error.
  """

  alias Alembic
  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJson

  # Behaviours

  @behaviour FromJson

  # Constants

  @parameter_options %{
                       field: :parameter,
                       member: %{
                         from_json: &FromJson.string_from_json/2
                       }
                     }

  # Struct

  defstruct [:parameter, :pointer]

  # Types

  @typedoc """
  An object containing references to the source of the [error](http://jsonapi.org/format/#error-objects), optionally
  including any of the following members:

  * `pointer` - JSON Pointer ([RFC6901](https://tools.ietf.org/html/rfc6901)) to the associated entity in the request
    document (e.g. `"/data"` for a primary data object, or `"/data/attributes/title"` for a specific attribute).
  * `parameter` - URL query parameter caused the error.
  """
  @type t :: %__MODULE__{
               parameter: String.t,
               pointer: Api.json_pointer
             }

  @doc """
  Descends `pointer` to `child` of current `pointer`

      iex> Alembic.Source.descend(
      ...>   %Alembic.Source{
      ...>     pointer: "/data"
      ...>   },
      ...>   1
      ...> )
      %Alembic.Source{
        pointer: "/data/1"
      }

  """
  @spec descend(t, String.t | integer) :: t
  def descend(source = %__MODULE__{pointer: pointer}, child) do
    %__MODULE__{source | pointer: "#{pointer}/#{child}"}
  end

  @doc """
  Converts JSON object to `t`.

  ## Valid Input

  A parameter can be the source of an error

      iex> Alembic.Source.from_json(
      ...>   %{
      ...>     "parameter" => "q",
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/source"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Source{
          parameter: "q"
        }
      }

  A member of a JSON object can be the source of an error, in which case a pointer to the location in the object will
  be given

      iex> Alembic.Source.from_json(
      ...>   %{
      ...>     "pointer" => "/data"
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/source"
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %Alembic.Source{
          pointer: "/data"
        }
      }

  ## Invalid Input

  It is assumed that only `"parameter"` or `"pointer"` can be set in a single error source (although that's not
  explicit in the JSON API specification), so setting both is an error

      iex> Alembic.Source.from_json(
      ...>   %{
      ...>     "parameter" => "q",
      ...>     "pointer" => "/data"
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/source"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
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
          ]
        }
      }

  A parameter **MUST** be a string

      iex> Alembic.Source.from_json(
      ...>   %{
      ...>     "parameter" => true,
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/source"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/errors/0/source/parameter` type is not string",
              meta: %{
                "type" => "string"
              },
              source: %Alembic.Source{
                pointer: "/errors/0/source/parameter"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  A pointer **MUST** be a string

      iex> Alembic.Source.from_json(
      ...>   %{
      ...>     "pointer" => ["data"],
      ...>   },
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/source"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/errors/0/source/pointer` type is not string",
              meta: %{
                "type" => "string"
              },
              source: %Alembic.Source{
                pointer: "/errors/0/source/pointer"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  """
  @spec from_json(%{String.t => String.t}, Error.t) :: FromJson.error
  def from_json(json, error_template)

  def from_json(%{"parameter" => _, "pointer" => _}, error_template) do
    {
      :error,
      %Document{
        errors: [
          Error.conflicting(error_template, ~w{parameter pointer})
        ]
      }
    }
  end

  def from_json(%{"parameter" => parameter}, error_template) do
    field_result = parameter
                   |> FromJson.string_from_json(Error.descend(error_template, "parameter"))
                   |> FromJson.put_key(:parameter)

    FromJson.merge({:ok, %__MODULE__{}}, field_result)
  end

  def from_json(%{"pointer" => pointer}, error_template) do
    field_result = pointer
                   |> FromJson.string_from_json(Error.descend(error_template, "pointer"))
                   |> FromJson.put_key(:pointer)

    FromJson.merge({:ok, %__MODULE__{}}, field_result)
  end

  defimpl Poison.Encoder do
    @doc """
    Encoded `Alembic.Source.t` as a `String.t` contain a JSON object with either a `"parameter"` or `"pointer"` member.
    Whichever field is `nil` in the `Alembic.Source.t` does not appear in the output.

    If `parameter` is set in the `Alembic.Source.t`, then the encoded JSON will only have "parameter"

        iex> Poison.encode(
        ...>   %Alembic.Source{
        ...>     parameter: "q"
        ...>   }
        ...> )
        {:ok, "{\\"parameter\\":\\"q\\"}"}

    If `pointer` is set in the `Alembic.Source.t`, then the encoded JSON will only have "pointer"

        iex> Poison.encode(
        ...>   %Alembic.Source{
        ...>     pointer: "/data"
        ...>   }
        ...> )
        {:ok, "{\\"pointer\\":\\"/data\\"}"}

    """
    @spec encode(@for.t, Keyword.t) :: String.t

    def encode(%@for{parameter: parameter, pointer: nil}, options) when is_binary(parameter) do
      Poison.Encoder.Map.encode(%{"parameter" => parameter}, options)
    end

    def encode(%@for{parameter: nil, pointer: pointer}, options) when is_binary(pointer) do
      Poison.Encoder.Map.encode(%{"pointer" => pointer}, options)
    end
  end
end
