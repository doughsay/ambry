defmodule AmbryWeb.Admin.SeriesLive.FormComponent do
  use AmbryWeb, :live_component

  alias Ambry.{Books, Series}

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    Checkbox,
    ErrorTag,
    Field,
    HiddenInputs,
    Inputs,
    Label,
    Select,
    Submit,
    TextInput
  }

  prop title, :string, required: true
  prop series, :any, required: true
  prop action, :atom, required: true
  prop return_to, :string, required: true

  data books, :list

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :books, books())}
  end

  @impl true
  def update(%{series: series} = assigns, socket) do
    changeset = Series.change_series(series, init_series_param(series))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"series" => series_params}, socket) do
    series_params = clean_series_params(series_params)

    changeset =
      socket.assigns.series
      |> Series.change_series(series_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"series" => series_params}, socket) do
    save_series(socket, socket.assigns.action, series_params)
  end

  def handle_event("add-book", _params, socket) do
    params =
      socket.assigns.changeset.params
      |> map_to_list("series_books")
      |> Map.update!("series_books", fn series_books_params ->
        series_books_params ++ [%{}]
      end)

    changeset = Series.change_series(socket.assigns.series, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp clean_series_params(params) do
    params
    |> map_to_list("series_books")
    |> Map.update!("series_books", fn series_books ->
      Enum.reject(series_books, fn series_book_params ->
        is_nil(series_book_params["id"]) && series_book_params["delete"] == "true"
      end)
    end)
  end

  defp save_series(socket, :edit, series_params) do
    case Series.update_series(socket.assigns.series, series_params) do
      {:ok, _series} ->
        {:noreply,
         socket
         |> put_flash(:info, "Series updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_series(socket, :new, series_params) do
    case Series.create_series(series_params) do
      {:ok, _series} ->
        {:noreply,
         socket
         |> put_flash(:info, "Series created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp books do
    Books.for_select()
  end

  defp map_to_list(params, key) do
    if Map.has_key?(params, key) do
      Map.update!(params, key, fn
        params_map when is_map(params_map) ->
          params_map
          |> Enum.sort_by(fn {index, _params} -> String.to_integer(index) end)
          |> Enum.map(fn {_index, params} -> params end)

        params_list when is_list(params_list) ->
          params_list
      end)
    else
      Map.put(params, key, [])
    end
  end

  defp init_series_param(series) do
    %{
      "series_books" => Enum.map(series.series_books, &%{"id" => &1.id})
    }
  end
end