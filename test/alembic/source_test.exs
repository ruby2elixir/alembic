defmodule Alembic.SourceTest do
  @moduledoc """
  Runs doctests for `Alembic.Source`
  """

  use ExUnit.Case, async: true

  alias Alembic.Error
  alias Alembic.FromJsonCase
  alias Alembic.Source

  # Tests

  doctest Source

  test "Poison.encode -> Poison.decode -> from_json/2 is idempotent when `parameter` is set" do
    assert_idempotent %Source{parameter: "q"}
  end

  test "Poison.encode -> Poison.decode -> from_json/2 is idempotent when `pointer` is set" do
    assert_idempotent %Source{pointer: "/data"}
  end

  # Private Functions

  defp assert_idempotent(original) do
    FromJsonCase.assert_idempotent error_template: %Error{
                                                     source: %Source{
                                                       pointer: "/errors/0/source"
                                                     }
                                                   },
                                   module: Source,
                                   original: original
  end
end
