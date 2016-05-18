defmodule Alembic.TestComment do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "comments" do
    field :text, :string

    belongs_to :post, Alembic.TestPost
  end
end
