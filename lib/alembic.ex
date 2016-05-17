defmodule Alembic do
  @moduledoc """
  [JSONAPI 1.0](http://jsonapi.org/format/1.0/)
  """

  @typedoc """
  A JSON object
  """
  @type json_object :: %{String.t => json}

  @typedoc """
  Parsed JSON from `Poison.decode!` or some other decoder.
  """
  @type json :: nil | true | false | list | float | integer | String.t | json_object

  @typedoc """
  A JSON Pointer as defined in [RFC6901](https://tools.ietf.org/html/rfc6901)
  """
  @type json_pointer :: String.t
end
