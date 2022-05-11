defmodule AmbryWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AmbryWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Ambry.Factory
      import AmbryWeb.ConnCase

      alias AmbryWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint AmbryWeb.Endpoint
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(Ambry.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Ambry.Factory.insert(:user)
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Ambry.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def register_and_put_user_api_token(%{conn: conn}) do
    user = Ambry.Factory.insert(:user)
    token = Ambry.Accounts.generate_user_session_token(user)
    encoded_token = Base.url_encode64(token)
    conn = Plug.Conn.put_req_header(conn, "authorization", "Bearer #{encoded_token}")

    %{conn: conn, user: user}
  end

  def remove_user_api_token(conn) do
    Plug.Conn.put_req_header(conn, "authorization", "")
  end
end
