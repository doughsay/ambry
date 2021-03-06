defmodule AmbryWeb.Admin.PaginationHelpers do
  @moduledoc """
  Helpers for building paginated / filterable lists.
  """

  @limit 15

  def limit do
    @limit
  end

  def get_list_opts(%Phoenix.LiveView.Socket{} = socket) do
    Map.get(socket.assigns, :list_opts, %{page: 1, filter: nil, sort: nil})
  end

  def get_list_opts(%{} = params) do
    page = get_page_from_params(params)
    filter = get_filter_from_params(params)
    sort = get_sort_from_params(params)

    %{
      page: page,
      filter: filter,
      sort: sort
    }
  end

  defp get_page_from_params(params) do
    case params |> Map.get("page", "1") |> Integer.parse() do
      {page, _} when page >= 1 -> page
      {_bad_page, _} -> 1
      :error -> 1
    end
  end

  defp get_filter_from_params(params) do
    case params |> Map.get("filter", "") |> String.trim() do
      "" -> nil
      filter -> filter
    end
  end

  defp get_sort_from_params(params) do
    case params |> Map.get("sort", "") |> String.trim() do
      "" -> nil
      sort -> sort
    end
  end

  def page_to_offset(page) do
    page * @limit - @limit
  end

  def prev_opts(list_opts) do
    list_opts
    |> Map.update!(:page, &(&1 - 1))
    |> patch_opts()
  end

  def next_opts(list_opts) do
    list_opts
    |> Map.update!(:page, &(&1 + 1))
    |> patch_opts()
  end

  def patch_opts(list_opts) do
    list_opts
    |> Enum.filter(fn
      {:page, 1} -> false
      {_key, nil} -> false
      _else -> true
    end)
    |> Map.new()
  end

  def sort_to_order(nil, _fields), do: nil

  def sort_to_order(sort, fields) do
    case String.split(sort, ".") do
      [""] -> nil
      [key] -> parse_order_key(key, fields)
      [key, dir] -> parse_key_with_dir(key, dir, fields)
      _else -> nil
    end
  end

  defp parse_key_with_dir(key, dir, fields) do
    key = parse_order_key(key, fields)
    dir = parse_order_dir(dir)

    if is_nil(key) || is_nil(dir) do
      nil
    else
      {key, dir}
    end
  end

  defp parse_order_dir("asc"), do: :asc
  defp parse_order_dir("desc"), do: :desc
  defp parse_order_dir(_dir), do: nil

  defp parse_order_key(key_string, fields) do
    fields
    |> Map.new(&{to_string(&1), &1})
    |> Map.get(key_string)
  end
end
