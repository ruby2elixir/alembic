defmodule Alembic.TestShirt do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "shirts" do
    field :size, :string
  end
end
