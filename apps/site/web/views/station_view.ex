defmodule Site.StationView do
  use Site.Web, :view

  @doc "Specify the mode each type is associated with"
  @spec fare_group(atom) :: String.t
  def fare_group(:bus), do: "bus_subway"
  def fare_group(:subway), do: "bus_subway"
  def fare_group(type), do: Atom.to_string(type)

  def location(station) do
    case station.latitude do
      nil -> URI.encode(station.address, &URI.char_unreserved?/1)
      _ -> "#{station.latitude},#{station.longitude}"
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

  def phone("") do
    ""
  end
  def phone(value) do
    content_tag(:a, value, href: "tel:#{value}")
  end

  def email("") do
    ""
  end
  def email(value) do
    display_value = value
    |> String.replace("@", "@\u200B")
    content_tag(:a, display_value, href: "mailto:#{value}")
  end

  def optional_link("", _) do
    nil
  end
  def optional_link(href, value) do
    href_value = case href do
                   <<"http://", _::binary>> -> href
                   <<"https://", _::binary>> -> href
                   _ -> "http://" <> href
                 end
    content_tag(:a, value, href: href_value, target: "_blank")
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
  def parking_type("basic"), do: "Parking"
  def parking_type(type), do: type |> String.capitalize

  @spec template_for_tab(String.t) :: String.t
  @doc "Returns the template to be rendered for the given tab"
  def template_for_tab("info"), do: "_info.html"
  def template_for_tab(_tab), do: "_schedule.html"

  @spec tab_class(String.t, String.t) :: String.t
  @doc "Given a station tab, and the selected tab, returns the CSS class for the given station tab"
  def tab_class("schedule", nil), do: "stations-tab stations-tab-selected"
  def tab_class(tab, selected) do
    "stations-tab" <> if tab == selected, do: " stations-tab-selected", else: ""
  end
end
