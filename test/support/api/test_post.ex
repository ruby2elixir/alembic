defmodule Alembic.TestPost do
  @moduledoc """
  A schema used in examples in `Alembic`
  """

  use Ecto.Schema

  schema "posts" do
    field :text, :string

    belongs_to :author, Alembic.TestAuthor
    has_many :comments, Alembic.TestComment
  end
end
