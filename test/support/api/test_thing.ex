defmodule Alembic.TestThing do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "things" do
    field :name, :string

    belongs_to :shirt, Alembic.TestShirt
  end
end
