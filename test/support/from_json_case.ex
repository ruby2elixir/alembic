defmodule Alembic.FromJsonCase do
  @moduledoc """
  Helpers for testing `from_json/2` implementations
  """

  import ExUnit.Assertions

  @doc """
  Asserts that the `:original` can be encoded, decode, and parsed from json and get back the `:original`, which proves
  idempotence of the `Poison.Encoder` implementation plus `Alembic.FromJson.from_json/2` callback cycle.

  ## Options

  All options are required.  They are just in a Keyword to make it clearer the meaning of each option

  * `:error_template` - `Alembic.Error.t` passed to `:module`'s `from_json/2`.
  * `:module` - Module with `@behaviour Alembic.FromJson`, so that it implements
    `Alembic.FromJson.from_json/2` callback.
  * `:original` - The original `Alembic` namespace struct that should be tested for encoding and parsing
    idempotence.
  """
  def assert_idempotent(options) do
    error_template = Keyword.get options, :error_template
    module = Keyword.get options, :module
    original = Keyword.get options, :original

    {:ok, encoded} = Poison.encode(original)
    {:ok, decoded} = Poison.decode(encoded)
    {:ok, from_decoded} = module.from_json(decoded, error_template)

    assert from_decoded == original
  end
end
