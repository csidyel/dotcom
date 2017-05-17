defmodule DetailedStopGroup do
  @moduledoc """
  Represents a route and DetailedStop pairing.
  The DetailedStops in the pairing all appear on
  the associated route.
  """

  alias Routes.Route
  alias Stops.Stop

  @type t :: {Route.t, [DetailedStop.t]}
  @type grouped_stops :: {Route.t, [Stop.t]}

  @doc """
  Generates a list of DetailedStopGroup for the given mode.
  The returned value will contain every route for the given mode
  and each route will contain every stop on that route
  """
  @spec from_mode(Routes.gtfs_route_type) :: [DetailedStopGroup.t]
  def from_mode(:subway) do
    :subway
    |> stops_for_mode()
    |> group_green_line()
    |> from_grouped_stops
  end
  def from_mode(mode) do
    mode
    |> stops_for_mode()
    |> from_grouped_stops()
  end

  @spec stops_for_mode(Routes.gtfs_route_type) :: [grouped_stops]
  defp stops_for_mode(mode) do
    mode
    |> Route.types_for_mode()
    |> Routes.Repo.by_type()
    |> Task.async_stream(&{&1, Stops.Repo.by_route(&1.id, 0)})
    |> Enum.map(fn {:ok, stops} -> stops end)
  end

  @spec from_grouped_stops([grouped_stops]) :: [DetailedStopGroup.t]
  defp from_grouped_stops(grouped_stops) do
    grouped_stops
    |> Task.async_stream(&build_featured_stops/1)
    |> Enum.map(fn {:ok, featured_stops} -> featured_stops end)
  end

  @spec build_featured_stops(grouped_stops) :: DetailedStopGroup.t
  defp build_featured_stops({route, stops}) do
    featured_stops = stops
    |> Enum.sort_by(& &1.name)
    |> Task.async_stream(&build_featured_stop(route, &1))
    |> Enum.map(fn {:ok, featured_stop} -> featured_stop end)
    {route, featured_stops}
  end

  @spec build_featured_stop(Route.t, Stop.t) :: DetailedStop.t
  defp build_featured_stop(route, stop) do
    features = Stops.Repo.stop_features(stop, [Route.icon_atom(route)], route.id == "Green")
    %DetailedStop{stop: stop, features: features}
  end

  @spec group_green_line([grouped_stops]) :: [grouped_stops]
  defp group_green_line(grouped_stops) do
    {green_branches, others} = grouped_stops
    |> Enum.partition(&String.starts_with?(elem(&1, 0).id, "Green-"))

    green_stops = green_branches
    |> Enum.flat_map(&elem(&1, 1))
    |> Enum.uniq

    [{%Route{name: "Green Line", id: "Green", type: 0}, green_stops} | others]
  end
end
