defmodule Alembic.FromJsonTest do
  @moduledoc """
  Runs doctests for `Alembic.FromJson`
  """

  use ExUnit.Case, async: true

  # Functions

  def assert_idempotent(options) do
    error_template = Keyword.get options, :error_template
    module = Keyword.get options, :module
    original = Keyword.get options, :original

    {:ok, encoded} = Poison.encode(original)
    {:ok, decoded} = Poison.decode(encoded)
    {:ok, from_decoded} = module.from_json(decoded, error_template)

    assert from_decoded == original
  end

  # Tests

  doctest Alembic.FromJson
end
