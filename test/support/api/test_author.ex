defmodule Alembic.TestAuthor do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "authors" do
    field :name, :string

    has_many :posts, Alembic.TestPost, foreign_key: :author_id
  end
end
