defmodule Site.StopView do
  use Site.Web, :view

  alias Fares.Summary
  alias Stops.Stop

  @origin_stations ["place-north", "place-sstat", "place-rugg", "place-bbsta"]

  @doc "Specify the mode each type is associated with"
  @spec fare_group(atom) :: String.t
  def fare_group(:bus), do: "bus_subway"
  def fare_group(:subway), do: "bus_subway"
  def fare_group(type), do: Atom.to_string(type)

  def location(stop) do
    case stop.latitude do
      nil -> URI.encode(stop.address, &URI.char_unreserved?/1)
      _ -> "#{stop.latitude},#{stop.longitude}"
    end
  end

  def pretty_accessibility("tty_phone"), do: "TTY Phone"
  def pretty_accessibility("escalator_both"), do: "Escalator (Both)"
  def pretty_accessibility(accessibility) do
    accessibility
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def optional_li(""), do: ""
  def optional_li(nil), do: ""
  def optional_li(value) do
    content_tag :li, value
  end

  def optional_link("", _) do
    nil
  end
  def optional_link(href, value) do
    content_tag(:a, value, href: external_link(href), target: "_blank")
  end

  def sort_parking_spots(spots) do
    spots
    |> Enum.sort_by(fn %{type: type} ->
      case type do
        "basic" -> 0
        "accessible" -> 1
        _ -> 2
      end
    end)
  end

  @spec mode_summaries(atom, {atom, String.t}) :: [Summary.t]
  @doc "Return the fare summaries for the given mode"
  def mode_summaries(:commuter, name) do
    filters = mode_filters(:commuter, name)
    summaries_for_filters(filters, :bus_subway) |> Enum.map(fn(summary) -> %{summary | modes: [:commuter]} end)
  end
  def mode_summaries(:ferry, name) do
    summaries_for_filters(mode_filters(:ferry, name), :ferry)
  end
  def mode_summaries(mode, name) do
    summaries_for_filters(mode_filters(mode, name), :bus_subway)
  end

  @spec mode_filters(atom, {atom, String.t}) :: [keyword()]
  defp mode_filters(:ferry, _name) do
    [[mode: :ferry, duration: :single_trip, reduced: nil],
     [mode: :ferry, duration: :month, reduced: nil]]
  end
  defp mode_filters(:commuter, name) do
    [[mode: :commuter, duration: :single_trip, reduced: nil, name: name],
     [mode: :commuter, duration: :month, media: [:commuter_ticket], reduced: nil, name: name]]
  end
  defp mode_filters(:bus_subway, name) do
    [[name: :local_bus, duration: :single_trip, reduced: nil] | mode_filters(:subway, name)]
  end
  defp mode_filters(mode, _name) do
    [[name: mode, duration: :single_trip, reduced: nil],
     [name: mode, duration: :week, reduced: nil],
     [name: mode, duration: :month, reduced: nil]]
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

  @spec accessibility_info(Stop.t) :: [Phoenix.HTML.Safe.t]
  @doc "Accessibility content for given stop"
  def accessibility_info(stop) do
    [(content_tag :p, format_accessibility_text(stop.name, stop.accessibility)),
    format_accessibility_options(stop)]
  end

  @spec format_accessibility_options(Stop.t) :: Phoenix.HTML.Safe.t | nil
  defp format_accessibility_options(stop) do
    if stop.accessibility && !Enum.empty?(stop.accessibility) do
      content_tag :p do
        stop.accessibility 
        |> Enum.filter(&(&1 != "accessible")) 
        |> Enum.map(&pretty_accessibility/1) 
        |> Enum.join(", ")
      end
    else
      content_tag :span, ""
    end
  end

  @spec format_accessibility_text(String.t, [String.t]) :: Phoenix.HTML.Safe.t
  defp format_accessibility_text(name, nil), do: content_tag(:em, "No accessibility information available for #{name}")
  defp format_accessibility_text(name, []), do: content_tag(:em, "No accessibility information available for #{name}")
  defp format_accessibility_text(name, ["accessible"]) do
    content_tag(:span, "#{name} is an accessible station. Accessible stations can be accessed by wheeled mobility devices.")
  end
  defp format_accessibility_text(name, _features), do: content_tag(:span, "#{name} has the following accessibility features:")

  @spec show_fares?(Stop.t) :: boolean
  @doc "Determines if the fare information for the given stop should be displayed"
  def show_fares?(stop) do
    !stop.id in @origin_stations
  end

  @spec summaries_for_filters([keyword()], atom) :: [Summary.t]
  defp summaries_for_filters(filters, mode) do
    filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(mode)
  end

  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("info"), do: "_info.html"
  def template_for_tab(_tab), do: "_schedule.html"

  @spec tab_class(String.t, String.t) :: String.t
  @doc "Given a station tab, and the selected tab, returns the CSS class for the given station tab"
  def tab_class(tab, tab), do: "stations-tab stations-tab-selected"
  def tab_class("schedule", nil), do: "stations-tab stations-tab-selected"
  def tab_class(_, _), do: "stations-tab"
end
