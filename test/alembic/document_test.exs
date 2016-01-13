defmodule Alembic.DocumentTest do
  @moduledoc """
  Run doctests for `Alembic.Document`
  """

  use ExUnit.Case, async: true

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJsonCase
  alias Alembic.Source

  doctest Document

  test "Poison.encode -> Poison.decode -> from_json/2 is idempotent for errors document" do
    error_template = %Error{
      source: %Source{
        pointer: ""
      }
    }

    {:error, response} = Document.from_json(%{}, error_template)

    FromJsonCase.assert_idempotent error_template: error_template,
                                   module: Document,
                                   original: response
  end
end
