defmodule AmbrySchema.Books do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias AmbrySchema.Resolvers

  node object(:series_book) do
    field :book_number, :decimal

    field :book, :book, resolve: dataloader(Resolvers)
    field :series, :series, resolve: dataloader(Resolvers)
  end

  node object(:series) do
    field :name, :string

    field :series_books, list_of(:series_book), resolve: dataloader(Resolvers)

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  node object(:book) do
    field :title, :string
    field :description, :string
    field :published, :date
    field :image_path, :string

    field :authors, list_of(:author), resolve: dataloader(Resolvers)
    field :series_books, list_of(:series_book), resolve: dataloader(Resolvers)

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  connection(node_type: :book)
end
