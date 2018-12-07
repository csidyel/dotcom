defmodule SiteWeb.ScheduleController.OriginDestination do
  @moduledoc """
  Assigns origin and destination to either a Stops.Stop.t or nil. Checks if the requested stops are valid
  for the route and direction (i.e., that they're on the line and accessible in the given direction).
  """

  use Plug.Builder
  alias Plug.Conn
  import UrlHelpers
  import Phoenix.Controller, only: [redirect: 2]

  plug(:assign_origin)
  plug(:assign_destination)

  def assign_origin(%Conn{query_params: %{"origin" => _}, assigns: %{route: route}} = conn, _) do
    origin = get_stop(conn, :origin)

    excluded_stops =
      ExcludedStops.excluded_origin_stops(
        conn.assigns.direction_id,
        route.id,
        conn.assigns.all_stops
      )

    if origin && origin.id not in excluded_stops do
      assign(conn, :origin, origin)
    else
      conn
      |> redirect(to: update_url(conn, origin: nil, destination: nil))
      |> halt
    end
  end

  # For inbound commuter rail trips, preselect the origin as the
  # terminal (i.e. either North or South stations).
  def assign_origin(%Conn{assigns: %{route: %Routes.Route{type: 2}, direction_id: 0}} = conn, _) do
    assign(conn, :origin, List.first(conn.assigns.all_stops))
  end

  # for bus trips, assign the origin if it's one of the hubs (South Station, North Station, Back Bay)
  def assign_origin(
        %Conn{assigns: %{route: %Routes.Route{type: 3}, all_stops: [%{id: hub_id} = origin | _]}} =
          conn,
        _
      )
      when hub_id in ["place-sstat", "place-north", "place-bbsta"] do
    assign(conn, :origin, origin)
  end

  # for green line, set origin
  def assign_origin(%Conn{assigns: %{route: %Routes.Route{type: 0}}} = conn, _) do
    assign(conn, :origin, List.first(conn.assigns.all_stops))
  end

  def assign_origin(conn, _) do
    assign(conn, :origin, nil)
  end

  def assign_destination(
        %Conn{query_params: %{"destination" => destination, "origin" => destination}} = conn,
        _
      ) do
    reset_destination(conn)
  end

  def assign_destination(%Conn{query_params: %{"destination" => _}} = conn, _) do
    destination = get_stop(conn, :destination)

    excluded_stops =
      ExcludedStops.excluded_destination_stops(
        conn.assigns.route.id,
        conn.assigns.origin && conn.assigns.origin.id
      )

    if destination && destination.id not in excluded_stops do
      assign(conn, :destination, destination)
    else
      reset_destination(conn)
    end
  end

  def assign_destination(conn, _) do
    assign(conn, :destination, nil)
  end

  def get_stop(conn, key) do
    stop_id = Map.get(conn.query_params, Atom.to_string(key))

    if Enum.find(conn.assigns.all_stops, &(&1.id == stop_id)) do
      Stops.Repo.get(stop_id)
    else
      nil
    end
  end

  defp reset_destination(conn) do
    conn
    |> redirect(to: update_url(conn, destination: nil))
    |> halt
  end
end
