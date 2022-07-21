defmodule AmbrySchema.Resolvers do
  @moduledoc false

  import Ecto.Query

  alias Absinthe.Relay

  alias Ambry.Authors.Author
  alias Ambry.Books.Book
  alias Ambry.Narrators.Narrator
  alias Ambry.People.Person
  alias Ambry.Repo
  alias Ambry.Series.{Series, SeriesBook}

  def list_books(args, _resolution) do
    Book
    |> order_by({:desc, :inserted_at})
    |> Relay.Connection.from_query(&Ambry.Repo.all/1, args)
  end

  def get_author(id), do: {:ok, Repo.get(Author, id)}
  def get_book(id), do: {:ok, Repo.get(Book, id)}
  def get_narrator(id), do: {:ok, Repo.get(Narrator, id)}
  def get_person(id), do: {:ok, Repo.get(Person, id)}
  def get_series_book(id), do: {:ok, Repo.get(SeriesBook, id)}
  def get_series(id), do: {:ok, Repo.get(Series, id)}

  def data, do: Dataloader.Ecto.new(Ambry.Repo, query: &query/2)

  def query(Author, _params), do: from(a in Author, order_by: {:asc, :name})
  def query(Narrator, _params), do: from(a in Narrator, order_by: {:asc, :name})
  def query(SeriesBook, _params), do: from(sb in SeriesBook, order_by: {:asc, :book_number})
  def query(queryable, _params), do: queryable
end
