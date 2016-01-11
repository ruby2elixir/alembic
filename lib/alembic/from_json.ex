defmodule Alembic.FromJson do
  @moduledoc """
  JSON objects that have constrained members in the [JSON API format](http://jsonapi.org/format/) are represented as
  `struct`s.  In order to convert plain, decoded JSON in `map`s and `list`s, `from_json/2` can be implemented by a
  module to convert to its `struct`.
  """

  alias Alembic.Document
  alias Alembic.Error

  # Types

  @typedoc """
  The action that generated the `Alembic.json`.  `:create` and `:update` allow additional formats.
  """
  @type action :: :create | :delete | :fetch | :update

  @typedoc """
  A result that can collect `singleton_result`s.
  """
  @type collectable_ok :: {:ok, collectable_value}

  @type collectable_result :: collectable_ok | error

  @typedoc """
  A value that can collect `singleton_value`s.
  """
  @type collectable_value :: list | map | struct

  @typedoc """
  Tagged-tuple returned when an error has occured in `from_json/2`.

  The format errors are in the errors section of the `Alembic.Document.t`, which can be sent back to
  sender of the original JSON API document so they can correct the errors.
  """
  @type error :: {:error, Document.t}

  @typedoc """
  The name of a field in a struct
  """
  @type field :: atom

  @typedoc """
  A result that has been tagged with the `field` in a struct to which it should be put when merged to the
  `collectable_ok`.
  """
  @type field_ok :: {:ok, {field, singleton_value}}

  @type field_result :: field_ok | error

  @typedoc """
  A key in a map or struct output from `from_json/2`
  """
  @type key :: field | String.t

  @typedoc """
  A result that has been tagged with the `key` in a struct or map to which it should be put when merged to the
  `collectable_ok`.
  """
  @type key_ok :: {:ok, {key, singleton_value}}

  @type key_result :: key_ok | error

  @typedoc """
  Whether the `:client` or `:server` sent the `json`.  The `:client` is allowed more formats on `:create` and `:update`
  `action`
  """
  @type sender :: :client | :server

  @typedoc """
  A result that can be merged into a `collectable_ok` whose `collectable_value` is a `list`.
  """
  @type singleton_ok :: {:ok, singleton_value}

  @type singleton_result :: singleton_ok | error

  @typedoc """
  A single value that can be merged into a `collective_value`.
  """
  @type singleton_value :: map | nil | String.t | struct

  # Callbacks

  @doc """
  Takes decoded JSON, such as from `Poison.decode/1`, and validates it for format and converts it to struct.

  # Parameters

  * `Alembic.json` - the decoded JSON from `Poison.decode/1` or some other JSON decoder.
  * `%Alembic.Error{
       meta: %{
         "action" => Alembic.FromJson.action,
         "sender" => Alembic.FromJson.sender
       },
       source: %Alembic.Source{
                 parameter: nil,
                 pointer: Alembic.json_pointer
               }
     }` - A prepolated error that includes a pointer for error repointing and meta information that influencing
     validation.  For example, some formats are only accepted on `:create` or `:update` from the `:client`.

  # Returns

  * `{:ok, map | struct}` - A validated type from under `Alembic`.
  * `{:error, %Alembic.Document{errors: [Alembic.Error.t]}}` - one or more errors was
    encountered when converting from decoded JSON to a validated JSON API document.  The format errors are in the errors
    section of the `Alembic.Document.t`, which can be sent back to sender of the original JSON API
    document so they can correct the errors.

    **NOTE: the `meta` from the passed in `Alembic.Error` should not be in the returned
    `Alembic.Document.t`'s `errors`, as that `meta` information is an implementation detail and for
    internal use in recursive calls to `Alembic.FromJson.from_json/2` only.**
  """
  @callback from_json(Alembic.json, Error.t) :: singleton_result

  # Functions

  @doc """
  Converts a JSON array using the `element_module` or `element_from_json` function.

  The `element_module` **MUST** implement the `Alembic.FromJson` behaviour.
  """
  @spec from_json_array(Alembic.json, Error.t, module) :: {:ok, [singleton_value]} | error
  def from_json_array(json_array, error_template, element_module) when is_list(json_array) and
                                                                       is_atom(element_module) do
    from_json_array(json_array, error_template, &element_module.from_json/2)
  end

  @spec from_json_array(Alembic.json, Error.t, (Alembic.json, Error.t -> singleton_result)) ::
        {:ok, [singleton_value]} | error
  def from_json_array(json_array, error_template, element_from_json) when is_list(json_array) and
                                                                          is_function(element_from_json, 2) do
    json_array
    |> Stream.with_index
    |> Stream.map(fn {element_json, index} ->
         element_from_json.(element_json, Error.descend(error_template, index))
       end)
    |> reduce({:ok, []})
  end

  def from_json_array(_, error_template, _) do
    error = Error.type(error_template, "array")

    {
      :error,
      # gets around circular reference if using %Document{} because from_json is implemented by Document and this needs
      # to return a Document
      struct(Document, errors: [error])
    }
  end

  @doc """
  Converts the member of a json object into a `field_result` that can be merged into a struct.

  ## Examples

  ### No Member

  If there is no member, then :error will be returned

      iex> Alembic.FromJson.from_parent_json_to_field_result(
      ...>   %{
      ...>     field: :data,
      ...>     member: %{
      ...>       module: Alembic.ResourceLinkage,
      ...>       name: "data"
      ...>     },
      ...>     parent: %{
      ...>       json: %{},
      ...>       error_template: %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/relationships/author"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      :error

  If there is no member, and the `:member` map contains `required: true`, then an error will be returned that the member
  is missing

      iex> Alembic.FromJson.from_parent_json_to_field_result(
      ...>   %{
      ...>     field: :id,
      ...>     member: %{
      ...>       from_json: &Alembic.FromJson.string_from_json/2,
      ...>       name: "id",
      ...>       required: true
      ...>     },
      ...>     parent: %{
      ...>       json: %{},
      ...>       error_template: %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/relationships/author"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/author/id` is missing",
              meta: %{
                "child" => "id"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/author"
              },
              status: "422",
              title: "Child missing"
            }
          ]
        }
      }

  ### `nil` member value

  If there is a member, but it's value is `nil` (meaning it was `null` in the unparsed JSON) then `nil` will be passed
  to the `member_module`'s `from_json/2` callback.  In most cases, the implementation should return `{:ok, nil}`, which
  will be tagged with the `field_name`.

      iex> Alembic.FromJson.from_parent_json_to_field_result(
      ...>   %{
      ...>     field: :links,
      ...>     member: %{
      ...>       module: Alembic.Links,
      ...>       name: "links"
      ...>     },
      ...>     parent: %{
      ...>       json: %{"links" => nil},
      ...>       error_template: %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/relationships/author"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      {:ok, {:links, nil}}

  ### Error on member

  Any errors from `member_module`'s `from_json/2` will be returned, but with the origin set to `parent_origin`

      iex> Alembic.FromJson.from_parent_json_to_field_result(
      ...>   %{
      ...>     field: :links,
      ...>     member: %{
      ...>       module: Alembic.Links,
      ...>       name: "links"
      ...>     },
      ...>     parent: %{
      ...>       json: %{"links" => []},
      ...>       error_template: %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/relationships/author"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/data/relationships/author/links` type is not links object",
              meta: %{
                "type" => "links object"
              },
              source: %Alembic.Source{
                pointer: "/data/relationships/author/links"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  ## Returns

  * `{:ok, {field_name, value}}` - a value (converted by `member_module`'s `from_json/2`) tagged with the `field_name`,
    so that it can be passed to `merge/2`.
  * `{:error, %Alembic.Document{errors: [Alembic.Error.t]}}` - an error from
    `member_module`'s `from_json/2`.
  * `:error` if the `member_name` isn't in `parent_json` at all.  This is to help distinguish no member from `nil`
    member values, as JSON API allows for `null` members in the case of empty to-one relationships.

  """
  @spec from_parent_json_to_field_result(
    %{parent: %{json: Alembic.json_object, error_template: Error.t},
      member: %{name: String.t, from_json: (Alembic.json, Origin.t -> singleton_result)} |
              %{name: String.t, module: module},
      field: atom}) :: field_result | error | :error

  def from_parent_json_to_field_result(options = %{member: %{name: member_name, module: member_module}}) do
    from_parent_json_to_field_result(
      %{options | member: %{name: member_name, from_json: &member_module.from_json/2}}
    )
  end

  def from_parent_json_to_field_result(%{
                                         field: field_name,
                                         member: member = %{name: member_name, from_json: from_json},
                                         parent: %{json: parent_json, error_template: parent_error_template}
                                       }) do
    case Map.fetch(parent_json, member_name) do
      {:ok, value_json} ->
        member_error_template = Error.descend(parent_error_template, member_name)

        value_json
        |> from_json.(member_error_template)
        |> put_key(field_name)
      :error ->
        if Map.get(member, :required, false) do
          {
            :error,
            # gets around circular reference if using %Document{} because from_json is implemented by Document and
            # this needs to return a Document
            struct(
              Document,
              errors: [
                Error.missing(parent_error_template, member_name)
              ]
            )
          }
        else
          :error
        end
    end
  end

  @doc """
  Merges the `singleton_result` into the `collectable_result`.

  ## `collectable_ok`

  If the `collectable_result` is a `collectable_ok`, then the `singleton_result` controls whether another
  `collectable_ok` or `error` is produced.

  ### `error`

  If the `singleton_result` is an error, then it becomes the merged result

      iex> collectable_ok = {:ok, ["One"]}
      iex> error = {
      ...>   :error,
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/1"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> }
      ...> merged_result = Alembic.FromJson.merge(collectable_ok, error)
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              source: %Alembic.Source{
                pointer: "/data/1"
              }
            }
          ]
        }
      }
      iex> merged_result == error
      true

  ### `field_ok`

  If the the result being merged in is for a field, then the field in the struct in `collectable_ok` is updated with the
  value from the `field_ok`.

      iex> collectable_ok = {:ok, %Alembic.Link{}}
      iex> Alembic.FromJson.merge(
      ...>   collectable_ok,
      ...>   {:ok, {:href, "http://example.com"}}
      ...> )
      {
        :ok,
        %Alembic.Link{
          href: "http://example.com"
        }
      }

  ### `key_ok`

  If the result being merged is for a key, then the key in the map in `collectable_ok` is updated with the value from
  `key_ok`

      iex> collectable_ok = {:ok, %{}}
      iex> Alembic.FromJson.merge(
      ...>   collectable_ok,
      ...>   {
      ...>     :ok,
      ...>     {
      ...>       "link_object",
      ...>       %Alembic.Link{
      ...>         href: "http://example.com",
      ...>         meta: %{
      ...>           "last_updated_on" => "2015-12-21"
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        %{
          "link_object" => %Alembic.Link{
            href: "http://example.com",
            meta: %{"last_updated_on" => "2015-12-21"}
          }
        }
      }

  ### `singleton_ok`

  If the result being merged is a singleton value, then it is add to the head of `collectable_ok`'s `list`.

      iex> collectable_ok = {:ok, []}
      iex> Alembic.FromJson.merge(
      ...>   collectable_ok,
      ...>   {
      ...>     :ok,
      ...>     %Alembic.Error{
      ...>       source: %Alembic.Source{
      ...>         pointer: "/data"
      ...>       }
      ...>     }
      ...>   }
      ...> )
      {
        :ok,
        [
          %Alembic.Error{
            source: %Alembic.Source{
              pointer: "/data"
            }
          }
        ]
      }

  ## `error`

  ### `ok`

  If the current collectable is an `error`, then ok results are ignored

      iex> error = {
      ...>   :error,
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/0"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> }
      iex> merged_error = Alembic.FromJson.merge(
      ...>   error,
      ...>   {:ok, {:field, "value"}}
      ...> )
      iex> merged_error == error
      true

  ### `error`

  If the collectable is an `error` and the `singleton_result` is also an error, then the
  `Alembic.Document.t` are merged so that `singleton_result`'s errors appear at the head of merged errors.

      iex> error = {
      ...>   :error,
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/0"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> }
      iex> Alembic.FromJson.merge(
      ...>   error,
      ...>   {
      ...>     :error,
      ...>     %Alembic.Document{
      ...>       errors: [
      ...>         %Alembic.Error{
      ...>           source: %Alembic.Source{
      ...>             pointer: "/data/1"
      ...>           }
      ...>         }
      ...>       ]
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              source: %Alembic.Source{
                pointer: "/data/1"
              }
            },
            %Alembic.Error{
              source: %Alembic.Source{
                pointer: "/data/0"
              }
            }
          ]
        }
      }

  If you want to get the `Alembic.Document.t` `errors` back in orginal order, use `reverse/1`.  `reduce/2`
  automatically does the `reverse/1`.
  """
  def merge(collable_result, singleton_result)

  @spec merge({:ok, list}, {:ok, singleton_value}) :: {:ok, list}
  def merge({:ok, list}, {:ok, value}) when is_list(list), do: {:ok, [value | list]}

  @spec merge({:ok, map}, {:ok, {key, singleton_value}}) :: {:ok, map}
  def merge({:ok, map}, {:ok, {key, value}}) when is_map(map) and is_binary(key), do: {:ok, Map.put(map, key, value)}

  @spec merge({:ok, struct}, {:ok, field, singleton_value}) :: {:ok, struct}
  def merge({:ok, updatable = %{__struct__: _}}, {:ok, {field, value}}) when is_atom(field) do
    {:ok, :maps.update(field, value, updatable)}
  end

  @spec merge(collectable_ok, error) :: error
  def merge({:ok, _}, error = {:error, _}), do: error

  @spec merge(error, key_ok) :: error
  def merge(error = {:error, _}, {:ok, _}), do: error

  @spec merge(error, error) :: error
  def merge({:error, collectable}, {:error, singleton}), do: {:error, Document.merge(collectable, singleton)}

  @doc """
  Add `key` to `singleton_ok` tuple, otherwise, does nothing.

  When result is `singleton_ok`, adds the key

      iex> Alembic.FromJson.put_key({:ok, %{}}, :data)
      {:ok, {:data, %{}}}

  But will not add a key if already present

      iex> try do
      ...>   Alembic.FromJson.put_key({:ok, {:data, %{}}}, :data)
      ...> rescue
      ...>   error -> error
      ...> end
      %FunctionClauseError{arity: 2, function: :put_key, module: Alembic.FromJson}

  When result is `error`, does nothing

      iex> result = {
      ...>   :error,
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> }
      iex> Alembic.FromJson.put_key(result, :data) == result
      true

  """
  def put_key(result, key)

  @spec put_key({:ok, value}, key) :: {:ok, {key, value}} when key: String.t | atom, value: singleton_value
  def put_key({:ok, value}, key) when (is_atom(key) or is_binary(key)) and not is_tuple(value), do: {:ok, {key, value}}

  @spec put_key(error, key) :: error when key: atom
  def put_key(error = {:error, _}, _), do: error

  @doc """
  Reduces `singleton_results` into an `Alembic.FromJson.collectable_result`.

  If there are any errors in singleton_results, then all the errors are accumulated into a single
  `Alembic.FromJson.error`.
  """
  @spec reduce([singleton_result] | Enumerable.t, collectable_result) :: collectable_result
  def reduce(singleton_results, collectable_result) do
    singleton_results
    |> Enum.reduce(
         collectable_result,
         fn
           (:error, acc) ->
             acc
           (singleton_result, acc) ->
             merge(acc, singleton_result)
         end
       )
    |> reverse
  end

  @doc """
  Since `merge/2` adds new `singleton_values` to the beginning of a `collectable_ok` list or
  `Alembic.Error.t`s to the beginning of the `Alembic.Document.t` `errors`, those lists
  need to be reversed to maintain original ordering after a series of `merge/2` calls.

  ## `error`

  Reverses the `Alembic.Document.t` `errors` to undo tail prepending done by `merge/2`

      iex> accumulated_error = {
      ...>   :error,
      ...>   %Alembic.Document{
      ...>     errors: [
      ...>       %Alembic.Error{
      ...>         detail: "The index `2` of `/data` is not a resource",
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/2"
      ...>         },
      ...>         title: "Element is not a resource"
      ...>       },
      ...>       %Alembic.Error{
      ...>         detail: "The index `1` of `/data` is not a resource",
      ...>         source: %Alembic.Source{
      ...>           pointer: "/data/1"
      ...>         },
      ...>         title: "Element is not a resource"
      ...>       }
      ...>     ]
      ...>   }
      ...> }
      iex> Alembic.FromJson.reverse(accumulated_error)
      {
        :error,
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
      }

  # `collectable_ok`

  ## lists

  List are ordered, but collect by prepending, so they need to be reversed

      iex> collectable_ok = {:ok, [3..4, 1..2]}
      iex> Alembic.FromJson.reverse(collectable_ok)
      {:ok, [1..2, 3..4]}

  ## maps

  Maps are unordered, so they just pass through

      iex> collectable_ok = {:ok, %{"b" => 2, "a" => 1}}
      iex> reversed_ok = Alembic.FromJson.reverse(collectable_ok)
      {:ok, %{"a" => 1, "b" => 2}}
      iex> reversed_ok == collectable_ok
      true

  """
  def reverse(collectable_result)

  @spec reverse(error) :: error
  def reverse({:error, document}), do: {:error, Document.reverse(document)}

  @spec reverse({:ok, list}) :: {:ok, list}
  def reverse({:ok, list}) when is_list(list), do: {:ok, Enum.reverse(list)}

  @spec reverse({:ok, map}) :: {:ok, map}
  def reverse({:ok, map}) when is_map(map), do: {:ok, map}

  @doc """
  Ensures that `json` is a `String.t`

  A string will be returned in an `ok` tuple

      iex> Alembic.FromJson.string_from_json(
      ...>   "422",
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/status"
      ...>     }
      ...>   }
      ...> )
      {:ok, "422"}

  A non-string will be returned in an `error` tuple where the errors `Alembic.Document.t` has a member
  type error

      iex> Alembic.FromJson.string_from_json(
      ...>   422,
      ...>   %Alembic.Error{
      ...>     source: %Alembic.Source{
      ...>       pointer: "/errors/0/status"
      ...>     }
      ...>   }
      ...> )
      {
        :error,
        %Alembic.Document{
          errors: [
            %Alembic.Error{
              detail: "`/errors/0/status` type is not string",
              meta: %{
                "type" => "string"
              },
              source: %Alembic.Source{
                pointer: "/errors/0/status"
              },
              status: "422",
              title: "Type is wrong"
            }
          ]
        }
      }

  """
  def string_from_json(json, error_template)

  @spec string_from_json(String.t, Error.t) :: {:ok, String.t}
  def string_from_json(string, _) when is_binary(string), do: {:ok, string}

  # Alembic.json -- [String.t]
  @spec string_from_json(nil | true | false | list | float | integer | Alembic.json_object, Error.t) :: error
  def string_from_json(_, error_template) do
    {
      :error,
      struct(
        Document,
        errors: [
          Error.type(error_template, "string")
        ]
      )
    }
  end
end
