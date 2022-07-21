defmodule AmbrySchema.People do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias AmbrySchema.Resolvers

  node object(:person) do
    field :name, :string
    field :description, :string
    field :image_path, :string

    field :authors, list_of(:author), resolve: dataloader(Resolvers)
    field :narrators, list_of(:narrator), resolve: dataloader(Resolvers)

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  node object(:author) do
    field :name, :string

    field :person, :person, resolve: dataloader(Resolvers)

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  node object(:narrator) do
    field :name, :string

    field :person, :person, resolve: dataloader(Resolvers)

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end
end
