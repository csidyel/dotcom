defmodule SiteWeb.PageView do
  import Phoenix.HTML.Tag

  use SiteWeb, :view

  def shortcut_icons do
    rows = for row <- [[:stations, :subway, :bus], [:commuter_rail, :ferry, :the_ride]] do
      content_tag(:div, Enum.map(row, &shortcut_icon/1), class: "m-homepage__shortcut-row")
    end
    content_tag(:div, rows, class: "m-homepage__shortcuts")
  end

  @spec shortcut_icon(atom) :: Phoenix.HTML.Safe.t
  defp shortcut_icon(id) do
    content_tag(:a, [
      id |> shortcut_svg_name() |> svg(),
      content_tag(:div, shortcut_text(id), class: "m-homepage__shortcut-text"),
    ], href: shortcut_link(id), class: "m-homepage__shortcut")
  end

  @spec shortcut_link(atom) :: String.t
  defp shortcut_link(:stations), do: stop_path(SiteWeb.Endpoint, :index)
  defp shortcut_link(:the_ride), do: cms_static_page_path(SiteWeb.Endpoint, "/accessibility/the-ride")
  defp shortcut_link(:nearby), do: transit_near_me_path(SiteWeb.Endpoint, :index)
  defp shortcut_link(mode), do: schedule_path(SiteWeb.Endpoint, :show, mode)

  @spec shortcut_text(atom) :: [Phoenix.HTML.Safe.t]
  defp shortcut_text(:stations) do
    [
      "Stations",
      content_tag(:span, [" &", tag(:br), "Stops"], class: "hidden-sm-down")
    ]
  end
  defp shortcut_text(:the_ride) do
    [
      content_tag(:span, [
        content_tag(:span, [
          "The",
          tag(:br),
        ], class: "hidden-sm-down"),
        "RIDE"
      ]),
    ]
  end
  defp shortcut_text(:commuter_rail) do
    [
      content_tag(:span, "Commuter ", class: "hidden-sm-down"),
      tag(:br, class: "hidden-sm-down"),
      "Rail",
      content_tag(:span, [" Lines"], class: "hidden-sm-down")
    ]
  end
  defp shortcut_text(:subway) do
    [
      "Subway",
      content_tag(:span, [tag(:br), "Lines"], class: "hidden-sm-down")
    ]
  end
  defp shortcut_text(mode) do
    [
      mode_name(mode),
      content_tag(:span, [tag(:br), "Routes"], class: "hidden-sm-down")
    ]
  end

  defp shortcut_svg_name(:stations), do: "icon-circle-t-default.svg"
  defp shortcut_svg_name(:the_ride), do: "icon-the-ride-default.svg"
  defp shortcut_svg_name(:commuter_rail), do: shortcut_svg_name(:"commuter-rail")
  defp shortcut_svg_name(mode), do: "icon-mode-#{mode}-default.svg"

  def schedule_separator do
    content_tag :span, "|", aria_hidden: "true", class: "schedule-separator"
  end

  @spec whats_happening_image(Content.WhatsHappeningItem.t) :: Phoenix.HTML.safe
  def whats_happening_image(%Content.WhatsHappeningItem{thumb: thumb, thumb_2x: nil}) do
    img_tag(thumb.url, alt: thumb.alt)
  end
  def whats_happening_image(%Content.WhatsHappeningItem{thumb: thumb, thumb_2x: thumb_2x}) do
    img_tag(thumb.url, alt: thumb.alt, sizes: "(max-width: 543px) 100vw, 33vw", srcset: "#{thumb.url} 304w, #{thumb_2x.url} 608w")
  end
end
