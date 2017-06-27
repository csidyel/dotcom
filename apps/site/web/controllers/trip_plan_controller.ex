defmodule Site.TripPlanController do
  use Site.Web, :controller
  alias Site.TripPlan.Map, as: TripPlanMap

  plug :require_google_maps

  def index(conn, %{"plan" => plan}) do
    query = TripPlan.Query.from_query(plan)

    render conn,
      query: query,
      route_map: with_itineraries(query, %{}, &routes_for_query/1),
      itinerary_maps: with_itineraries(query, [], &itinerary_maps/1)
  end
  def index(conn, _params) do
    render(conn, :index, initial_map_src: TripPlanMap.initial_map_src())
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  defp with_itineraries(query, default, function)
  defp with_itineraries(%TripPlan.Query{itineraries: {:ok, itineraries}}, _default, function) do
    function.(itineraries)
  end
  defp with_itineraries(%TripPlan.Query{}, default, _function) do
    default
  end

  @spec routes_for_query([TripPlan.Itinerary.t]) :: %{Routes.Route.id_t => Routes.Route}
  defp routes_for_query(itineraries) do
    itineraries
    |> Enum.flat_map(&TripPlan.Itinerary.route_ids/1)
    |> Enum.uniq
    |> Map.new(&{&1, Routes.Repo.get(&1)})
  end

  @spec itinerary_maps([TripPlan.Itinerary.t]) :: [TripPlanMap.t]
  defp itinerary_maps(itineraries) do
    Enum.map(itineraries, &TripPlanMap.itinerary_map/1)
  end
end
