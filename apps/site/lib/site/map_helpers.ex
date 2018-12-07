defmodule Site.MapHelpers do
  alias Routes.Route
  alias GoogleMaps.MapData.Marker

  import SiteWeb.Router.Helpers, only: [static_url: 2]

  @spec map_pdf_url(atom) :: String.t()
  def map_pdf_url(:subway) do
    static_url(
      SiteWeb.Endpoint,
      "/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf"
    )
  end

  def map_pdf_url(:bus) do
    static_url(SiteWeb.Endpoint, "/sites/default/files/maps/2018-04-map-system.pdf")
  end

  def map_pdf_url(:commuter_rail) do
    static_url(SiteWeb.Endpoint, "/sites/default/files/maps/2017-05-map-commuter-rail-v30.pdf")
  end

  def map_pdf_url(:ferry) do
    static_url(SiteWeb.Endpoint, "/sites/default/files/maps/2018-08-ferry-map.pdf")
  end

  def map_pdf_url(:commuter_rail_zones) do
    static_url(
      SiteWeb.Endpoint,
      "/sites/default/files/maps/2018-commuter-rail-zones-spider-bw.pdf"
    )
  end

  @spec thumbnail(atom) :: String.t()
  def thumbnail(:subway) do
    static_url(SiteWeb.Endpoint, "/images/map-thumbnail-subway.jpg")
  end

  def thumbnail(:commuter_rail) do
    static_url(SiteWeb.Endpoint, "/images/map-thumbnail-commuter-rail.jpg")
  end

  def thumbnail(:commuter_rail_zones) do
    static_url(SiteWeb.Endpoint, "/images/map-thumbnail-fare-zones.jpg")
  end

  def thumbnail(:bus) do
    static_url(SiteWeb.Endpoint, "/images/map-thumbnail-bus-system.jpg")
  end

  def thumbnail(:ferry) do
    static_url(SiteWeb.Endpoint, "/images/map-thumbnail-ferry.jpg")
  end

  @spec image(atom) :: String.t()
  def image(:subway) do
    static_url(SiteWeb.Endpoint, "/images/map-medium-rapidtransit.png")
  end

  def image(:ferry) do
    static_url(SiteWeb.Endpoint, "/sites/default/files/maps/2018-08-ferry-map.png")
  end

  @doc "Returns the map color that should be used for the given route"
  # The Ferry color: 5DA9E8 isn't used on any maps right now.
  @spec route_map_color(Route.t() | nil) :: String.t()
  def route_map_color(%Route{type: 3}), do: "FFCE0C"
  def route_map_color(%Route{type: 2}), do: "A00A78"
  def route_map_color(%Route{id: "Blue"}), do: "0064C8"
  def route_map_color(%Route{id: "Red"}), do: "FF1428"
  def route_map_color(%Route{id: "Mattapan"}), do: "FF1428"
  def route_map_color(%Route{id: "Orange"}), do: "FF8200"
  def route_map_color(%Route{id: "Green" <> _}), do: "428608"
  def route_map_color(_), do: "000000"

  @doc """
  Returns the map icon path for the given route. An optional size
  can be given. A Size of :mid represents the larger stop icons.
  If no size is specified, the smaller icons are shown
  """
  @spec map_stop_icon_path(Marker.size() | nil, boolean) :: String.t()
  def map_stop_icon_path(size, filled \\ false)
  def map_stop_icon_path(:mid, false), do: "000000-dot-mid"
  def map_stop_icon_path(:mid, true), do: "000000-dot-filled-mid"
  def map_stop_icon_path(_size, true), do: "000000-dot-filled"
  def map_stop_icon_path(_size, false), do: "000000-dot"
end
