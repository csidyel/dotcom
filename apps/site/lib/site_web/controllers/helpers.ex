defmodule SiteWeb.ControllerHelpers do
  alias Plug.Conn
  alias Routes.Route
  import Plug.Conn, only: [put_status: 2, halt: 1]
  import Phoenix.Controller, only: [render: 4]

  @valid_resp_headers [
    "content-type",
    "date",
    "etag",
    "expires",
    "last-modified",
    "cache-control"
  ]

  @doc "Find all the assigns which are Tasks, and await_assign them"
  def await_assign_all(conn, timeout \\ 5_000) do
    task_keys = for {key, %Task{}} <- conn.assigns do
      key
    end
    Enum.reduce(task_keys, conn, fn key, conn -> Conn.await_assign(conn, key, timeout) end)
  end

  defmacro call_plug(conn, module) do
    opts = Macro.expand(module, __ENV__).init([])
    quote do
      unquote(module).call(unquote(conn), unquote(opts))
    end
  end

  def render_404(conn) do
    conn
    |> put_status(:not_found)
    |> render(SiteWeb.ErrorView, "404.html", [])
    |> halt()
  end

  @spec filter_routes([{atom, [Route.t]}], [atom]) :: [{atom, [Route.t]}]
  def filter_routes(grouped_routes, filter_lines) do
    grouped_routes
    |> Enum.map(fn {mode, lines} ->
      if mode in filter_lines do
        {mode, lines |> Enum.filter(&Routes.Route.key_route?/1)}
      else
        {mode, lines}
      end
    end)
  end

  @spec filtered_grouped_routes([atom]) :: [{atom, [Route.t]}]
  def filtered_grouped_routes(filters) do
    Routes.Repo.all
    |> Routes.Group.group
    |> filter_routes(filters)
  end

  @spec get_grouped_route_ids([{atom, [Route.t]}]) :: [String.t]
  def get_grouped_route_ids(grouped_routes) do
    grouped_routes
    |> Enum.flat_map(fn {_mode, routes} -> routes end)
    |> Enum.map(& &1.id)
  end

  @spec assign_all_alerts(Conn.t, []) :: Conn.t
  def assign_all_alerts(%{assigns: %{route: %Routes.Route{id: route_id, type: route_type}}} = conn, _opts) do
    informed_entity_matchers = [
      %Alerts.InformedEntity{route_type: route_type, direction_id: conn.assigns[:direction_id]},
      %Alerts.InformedEntity{route: route_id, direction_id: conn.assigns[:direction_id]}
    ]
    alerts =
      route_id
      |> Alerts.Repo.by_route_id_and_type(route_type, conn.assigns.date_time)
      |> Alerts.Match.match(informed_entity_matchers)

    Conn.assign(conn, :all_alerts, alerts)
  end

  @doc """
  Gets a remote static file and forwards it to the client.
  If there's a problem with the response, returns a 404 Not Found.
  This also returns some (but not all) headers back to the client.
  Headers like ETag and Last-Modified should help with caching.
  """
  @spec forward_static_file(Conn.t, String.t) :: Conn.t
  def forward_static_file(conn, url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body, headers: headers}} ->
        conn
        |> add_headers_if_valid(headers)
        |> Conn.send_resp(:ok, body)
      _ ->
        Conn.send_resp(conn, :not_found, "")
    end
  end

  @spec add_headers_if_valid(Conn.t, [{String.t, String.t}]) :: Conn.t
  defp add_headers_if_valid(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, conn ->
      if String.downcase(key) in @valid_resp_headers do
        Conn.put_resp_header(conn, String.downcase(key), value)
      else
        conn
      end
    end)
  end

  @spec check_cms_or_404(Conn.t) :: Conn.t
  def check_cms_or_404(conn) do
    SiteWeb.ContentController.page(conn, [])
  end

  @spec best_cms_path(map, String.t) :: String.t
  def best_cms_path(%{"id" => id}, full_path), do: parse_id(id, full_path)
  def best_cms_path(%{"alias" => [id]}, full_path), do: parse_id(id, full_path)
  def best_cms_path(%{"project_id" => _pid, "update_id" => uid}, full_path), do: parse_id(uid, full_path)
  def best_cms_path(%{"event_id" => event_id}, full_path), do: parse_id(event_id, full_path)
  def best_cms_path(_, full_path), do: full_path

  @spec parse_id(String.t, String.t) :: String.t
  defp parse_id(id, full_path) do
    id
    |> Integer.parse()
    |> do_best_cms_path(full_path)
  end

  @spec do_best_cms_path({integer, String.t} | :error, String.t) :: String.t
  defp do_best_cms_path({id, ""}, _), do: "/node/#{id}"
  defp do_best_cms_path(_, full_path), do: full_path
end
