defmodule Ambry.People.Person do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ambry.Authors.Author
  alias Ambry.Narrators.Narrator

  schema "people" do
    has_many :authors, Author
    has_many :narrators, Narrator

    field :name, :string
    field :description, :string
    field :image_path, :string

    timestamps()
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :description, :image_path])
    |> validate_required([:name])
  end
end
