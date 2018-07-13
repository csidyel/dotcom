defmodule SiteWeb.StopView do
  use SiteWeb, :view

  alias Stops.Stop
  alias Routes.Route
  alias Fares.RetailLocations.Location
  alias SiteWeb.PartialView.SvgIconWithCircle
  import SiteWeb.StopView.Parking

  @origin_stations ["place-north", "place-sstat", "place-rugg", "place-bbsta", "Boat-Long"]

  @spec location(Stops.Stop.t) :: String.t
  def location(%Stops.Stop{latitude: nil, address: address}), do: URI.encode(address, &URI.char_unreserved?/1)
  def location(%Stops.Stop{latitude: lat, longitude: lng}), do: "#{lat},#{lng}"

  @spec pretty_accessibility(String.t) :: [String.t]
  def pretty_accessibility("tty_phone"), do: ["TTY Phone"]
  def pretty_accessibility("escalator_both"), do: ["Escalator (up and down)"]
  def pretty_accessibility("escalator_up"), do: ["Escalator (up only)"]
  def pretty_accessibility("escalator_down"), do: ["Escalator (down only)"]
  def pretty_accessibility("ramp"), do: ["Long ramp"]
  def pretty_accessibility("fully_elevated_platform"), do: ["Full high level platform to provide level boarding to every car in a train set"]
  def pretty_accessibility("elevated_subplatform"), do: ["Mini high level platform to provide level boarding to certain cars in a train set"]
  def pretty_accessibility("unknown"), do: []
  def pretty_accessibility("accessible"), do: []
  def pretty_accessibility(accessibility) do
    [
      accessibility
      |> String.split("_")
      |> Enum.join(" ")
      |> String.capitalize()
    ]
  end

  @spec render_alerts([Alerts.Alert], DateTime.t, Stop.t) :: Phoenix.HTML.safe | String.t
  def render_alerts(stop_alerts, date, stop) do
    SiteWeb.AlertView.modal alerts: stop_alerts,
                            hide_t_alerts: true,
                            time: date,
                            route: %{id: stop.id |> String.replace(" ", "-"), name: stop.name}
  end

  @spec fare_mode([atom]) :: atom
  @doc "Determine what combination of bus and subway are present in given types"
  def fare_mode(types) do
    cond do
      :subway in types && :bus in types -> :bus_subway
      :subway in types -> :subway
      :bus in types -> :bus
    end
  end

  @spec aggregate_routes([map()]) :: [map()]
  @doc "Combine multiple routes on the same subway line. Combines Green Line branches into a single route."
  def aggregate_routes(routes) do
    routes
    |> Enum.uniq_by(&Phoenix.Param.to_param/1)
    |> Enum.map(&Route.to_naive/1)
  end

  @spec accessibility_info(Stop.t, [Routes.Route.gtfs_route_type]) :: Phoenix.HTML.Safe.t
  @doc "Accessibility content for given stop"
  def accessibility_info(stop, route_types) do
    [
      content_tag(:p,
                  [
                   format_accessibility_text(stop, route_types),
                   format_accessibility_prefix(stop, route_types)
                  ]),
      format_accessibility_options(stop),
      accessibility_contact_link(stop)
    ]
  end

  @spec format_accessibility_prefix(Stop.t, [Routes.Route.gtfs_route_type]) :: Phoenix.HTML.Safe.t
  def format_accessibility_prefix(stop, route_types) do
    case Enum.flat_map(stop.accessibility, &pretty_accessibility/1) do
      [] -> []
      _ ->
        cond do
          stop.id == "place-asmnl" ->
            [" ", stop.name, " has the following features:"]
          Stop.accessible?(stop) || !bus_route?(route_types) ->
            [" It has the following features:"]
          Stop.accessibility_known?(stop) ->
            [" ", stop.name, " has the following features:"]
          true -> []
        end
    end
  end

  @spec format_accessibility_options(Stop.t) :: Phoenix.HTML.Safe.t
  defp format_accessibility_options(stop)
  defp format_accessibility_options(stop) do
    case Enum.flat_map(stop.accessibility, &pretty_accessibility/1) do
      [] -> []
      features ->
        content_tag :ul, Enum.map(Enum.sort(features), fn(feature) -> content_tag :li, feature end)
    end
  end

  defp significant_accessibility_barriers_text(stop) do
    ["Significant accessibility barriers exist at ", stop.name, ", but customers can board/exit the ",
     significant_accessibility_train_name(stop), " using a mobile lift."]
  end

  defp significant_accessibility_train_name(%Stop{id: "place-asmnl"}), do: "Mattapan Trolley"
  defp significant_accessibility_train_name(_stop), do: "train"

  @spec format_accessibility_text(Stop.t, [Routes.Route.gtfs_route_type]) :: iodata
  defp format_accessibility_text(%Stop{id: id} = stop, _) when id in ["place-lech", "place-brkhl", "place-newtn", "place-asmnl"] do
    significant_accessibility_barriers_text(stop)
  end
  defp format_accessibility_text(stop, route_types) do
    bus_route? = bus_route?(route_types)

    cond do
      Stop.accessible?(stop) ->
        [stop.name, " is accessible."]
      Stop.accessibility_known?(stop) ->
        accessibility_text(stop.name,
                           bus_route?,
                           "Significant",
                           "Customers using wheeled mobility devices may need to board at street level. Bus operator will need to relocate bus for safe boarding and exiting."
        )
      :unknown ->
        accessibility_text(stop.name,
                           bus_route?,
                           "Minor to moderate",
                           "Bus operator may need to relocate bus for safe boarding and exiting."
        )
    end
  end

  @spec accessibility_text(String.t, boolean, String.t, String.t) :: iodata
  defp accessibility_text(stop_name, true, main_text, bus_text) do
      [main_text, " accessibility barriers exist at ", stop_name, ". ", bus_text]
  end
  defp accessibility_text(stop_name, false, main_text, _bus_text) do
      [main_text, " accessibility barriers exist at ", stop_name, "."]
  end

  @spec bus_route?([Routes.Route.gtfs_route_type]) :: boolean
  defp bus_route?(route_types), do: Enum.any?(route_types, &(&1 == :bus))

  @spec accessibility_contact_link(Stop.t) :: Phoenix.HTML.Safe.t
  defp accessibility_contact_link(stop) do
    case stop.accessibility do
      [] -> []
      ["accessible"] -> []
      ["unknown"] -> []
      _ ->
        link to: customer_support_path(SiteWeb.Endpoint, :index) do
          content_tag :p do
            ["Problem with an elevator, escalator, or other accessibility issue? Send us a message ",
             fa("arrow-right")]
          end
        end
    end
  end

  @spec origin_station?(Stop.t) :: boolean
  def origin_station?(stop) do
    stop.id in @origin_stations
  end

  @spec fare_surcharge?(Stop.t) :: boolean
  def fare_surcharge?(stop) do
    stop.id in ["place-bbsta", "place-north", "place-sstat"]
  end

  @spec parking_type(String.t) :: String.t
  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("departures"), do: "_departures.html"
  def template_for_tab(_tab), do: "_info.html"

  @spec schedule_template(Route.route_type) :: String.t
  @doc "Returns the template to render schedules for the given mode."
  def schedule_template(:commuter_rail), do: "_commuter_schedule.html"
  def schedule_template(_), do: "_mode_schedule.html"

  @spec has_alerts?([Alerts.Alert.t], Date.t, Alerts.InformedEntity.t) :: boolean
  @doc "Returns true if the given route has alerts."
  def has_alerts?(alerts, date, informed_entity) do
    alerts
    |> Enum.reject(&Alerts.Alert.is_notice?(&1, date))
    |> Alerts.Match.match(informed_entity)
    |> Enum.empty?
    |> Kernel.not
  end

  @spec station_schedule_empty_msg(atom) :: Phoenix.HTML.Safe.t
  def station_schedule_empty_msg(mode) do
    content_tag :div, class: "station-schedules-empty station-route-row" do
      [
        "There are no upcoming ",
        mode |> mode_name() |> String.downcase,
        " departures until the start of the next day's service."
      ]
    end
  end

  @doc """
  If some predictions for the same route and variation have a combination of predictions where
  some have status and some have time, we want to filter out the ones with only a time. This avoids
  a mix of "stops away" and "minutes away" on one line of upcoming departures.
  Given that the records are sorted such that those with predictions come first, we can look at the
  first element to see if filtering is required.
  """
  @spec filter_times_without_stops_away([PredictedSchedule.t]) :: [PredictedSchedule.t]
  def filter_times_without_stops_away([first | _]  = predicted_schedules) do
    if PredictedSchedule.status(first) do
      Enum.filter(predicted_schedules, &PredictedSchedule.status/1)
    else
      predicted_schedules
    end
  end
  def filter_times_without_stops_away([]) do
    []
  end

  @spec time_differences([PredictedSchedule.t], DateTime.t) :: [Phoenix.HTML.Safe.t]
  @doc "A list of time differences for the predicted schedules, with the empty ones removed."
  def time_differences(predicted_schedules, date_time) do
    predicted_schedules
    |> Enum.reject(&PredictedSchedule.empty?/1)
    |> Enum.sort_by(&PredictedSchedule.sort_with_status/1)
    |> Enum.take(3)
    |> filter_times_without_stops_away()
    |> Enum.flat_map(fn departure ->
      case PredictedSchedule.Display.time_difference(departure, date_time) do
        "" -> []
        difference -> [difference]
      end
    end)
  end

  @doc "Returns the url for a map showing directions from a stop to a retail location."
  @spec retail_location_directions_link(Location.t, Stop.t) :: Phoenix.HTML.Safe.t
  def retail_location_directions_link(%Location{latitude: retail_lat, longitude: retail_lng}, %Stop{latitude: stop_lat, longitude: stop_lng}) do
    href = GoogleMaps.direction_map_url({stop_lat, stop_lng}, {retail_lat, retail_lng})
    content_tag :a, ["View on map ", fa("arrow-right")], href: href, class: "no-wrap"
  end

  @doc "Creates the name to be used for station info tab"
  @spec info_tab_name([Routes.Group.t]) :: String.t
  def info_tab_name([bus: _]) do
    "Stop Info"
  end
  def info_tab_name(_) do
    "Station Info"
  end

  @doc "returns small icons for features in given DetailedStop"
  @spec feature_icons(DetailedStop.t) :: Phoenix.HTML.Safe.t
  def feature_icons(%DetailedStop{features: features}) do
    for feature <- features do
      stop_feature_icon(feature, :small)
    end
  end

  @doc """
  Returns correct svg Icon for the given feature
  """
  @spec stop_feature_icon(Stops.Repo.stop_feature, :small | :default) :: Phoenix.HTML.Safe.t
  def stop_feature_icon(feature, size \\ :default)
  def stop_feature_icon(feature, size) when is_atom(size) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: stop_feature_icon_atom(feature), size: size})
  end

  defp stop_feature_icon_atom(branch) when branch in [:"Green-B", :"Green-C", :"Green-D", :"Green-E"] do
    Routes.Route.icon_atom(%Route{id: Atom.to_string(branch), type: 0})
  end
  defp stop_feature_icon_atom(feature) do
    feature
  end

  @spec station_name_class(Keyword.t) :: String.t
  def station_name_class([{:bus, _}]), do: "station__name"
  def station_name_class(_), do: "station__name station__name--upcase"

  @spec render_header_modes(Keyword.t, integer | nil) :: [Phoenix.HTML.Safe.t]
  def render_header_modes(grouped_routes, zone_number) do
    for mode <- [:subway, :ferry, :commuter_rail, :bus] do
      do_render_header_modes(mode, Keyword.get(grouped_routes, mode, []), zone_number)
    end
  end

  defp do_render_header_modes(_type, [], _zone) do
    []
  end
  defp do_render_header_modes(type, [%Route{} | _] = routes, zone) do
    [
      render_header_mode(type, routes),
      render_cr_zone(type, zone)
    ]
  end

  @spec render_header_mode(Route.gtfs_route_type, [Route.t]) :: [Phoenix.HTML.Safe.t]
  defp render_header_mode(_type, []) do
    []
  end
  defp render_header_mode(:subway, routes) do
    for route <- aggregate_routes(routes) do
      route
      |> line_icon(:default)
      |> do_render_header_mode(route.name, route)
    end
  end
  defp render_header_mode(type, [route | _]) do
    [
      type
      |> mode_icon(:default)
      |> do_render_header_mode(mode_name(type), route)
    ]
  end

  @spec do_render_header_mode(Phoenix.HTML.Safe.t, String.t, Route.t) :: Phoenix.HTML.Safe.t
  defp do_render_header_mode({:safe, _} = icon, <<text::binary>>, %Route{} = route) do
    content_tag(:span, [
      content_tag(:span, icon, class: "station__header-icon#{unless route.type == 3 do " hidden-md-up" end}"),
      render_header_mode_name(route, text)
    ], class: "station__header-feature")
  end

  @spec render_header_mode_name(Route.t, String.t) :: [Phoenix.HTML.Safe.t]
  defp render_header_mode_name(%Route{type: 3}, _) do
    []
  end
  defp render_header_mode_name(%Route{} = route, text) do
    [content_tag(:span, text, class: "station__header-description #{header_mode_bg_class(route)}")]
  end

  @spec render_cr_zone(Route.gtfs_route_type, integer | nil) :: [Phoenix.HTML.Safe.t]
  defp render_cr_zone(:commuter_rail, nil) do
    []
  end
  defp render_cr_zone(:commuter_rail, zone) do
    [content_tag(:span, [
      content_tag(:span, "Zone #{zone}", class: "station__header-icon c-icon__cr-zone")
    ], class: "station__header-feature")]
  end
  defp render_cr_zone(_, _) do
    []
  end

  @spec header_mode_bg_class(Route.t) :: String.t
  defp header_mode_bg_class(%Route{type: type} = route) when type in [0, 1] do
    route
    |> route_to_class()
    |> do_header_mode_bg_class()
  end
  defp header_mode_bg_class(%Route{type: type}) do
    type
    |> Route.type_atom()
    |> CSSHelpers.atom_to_class()
    |> do_header_mode_bg_class()
  end

  @spec do_header_mode_bg_class(String.t) :: String.t
  defp do_header_mode_bg_class(modifier), do: "u-bg--#{modifier}"
end
