defmodule AmbrySchema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias AmbrySchema.{Books, People, Resolvers}

  import_types Absinthe.Type.Custom
  import_types People
  import_types Books

  node interface do
    resolve_type fn
      %Ambry.Authors.Author{}, _res -> :author
      %Ambry.Books.Book{}, _res -> :book
      %Ambry.Narrators.Narrator{}, _res -> :narrator
      %Ambry.People.Person{}, _res -> :person
      %Ambry.Series.Series{}, _res -> :series
      %Ambry.Series.SeriesBook{}, _res -> :series_book
    end
  end

  query do
    node field do
      resolve fn
        %{type: :author, id: id}, _res -> Resolvers.get_author(id)
        %{type: :book, id: id}, _res -> Resolvers.get_book(id)
        %{type: :narrator, id: id}, _res -> Resolvers.get_narrator(id)
        %{type: :person, id: id}, _res -> Resolvers.get_person(id)
        %{type: :series, id: id}, _res -> Resolvers.get_series(id)
        %{type: :series_book, id: id}, _res -> Resolvers.get_series_book(id)
      end
    end

    connection field :books, node_type: :book do
      resolve &Resolvers.list_books/2
    end
  end

  @impl Absinthe.Schema
  def context(ctx) do
    loader = Dataloader.add_source(Dataloader.new(), Resolvers, Resolvers.data())

    Map.put(ctx, :loader, loader)
  end

  @impl Absinthe.Schema
  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
