defmodule SiteWeb.StopListViewTest do
  use SiteWeb.ConnCase, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]
  import SiteWeb.ScheduleView.StopList

  alias CMS.Repo
  alias Routes.Route
  alias Schedules.Departures
  alias Site.StopBubble
  alias SiteWeb.ScheduleView
  alias Stops.{RouteStop, Stop}

  @trip %Schedules.Trip{name: "101", headsign: "Headsign", direction_id: 0, id: "1"}
  @stop %Stops.Stop{id: "stop-id", name: "Stop Name"}
  @route %Routes.Route{type: 3, id: "1"}
  @prediction %Predictions.Prediction{
    departing?: true,
    direction_id: 0,
    status: "On Time",
    trip: @trip
  }
  @schedule %Schedules.Schedule{
    route: @route,
    trip: @trip,
    stop: @stop
  }
  @vehicle %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: @route.id}
  @predicted_schedule %PredictedSchedule{prediction: @prediction, schedule: @schedule}
  @trip_info %TripInfo{
    route: @route,
    vehicle: @vehicle,
    vehicle_stop_name: @stop.name,
    times: [@predicted_schedule]
  }
  @assigns %{
    bubbles: [{nil, :terminus}],
    stop: %RouteStop{branch: nil, id: "stop", zone: "1", stop_features: []},
    route: %Route{id: "route_id", type: 1},
    direction_id: 1,
    conn: SiteWeb.Endpoint,
    add_expand_link?: false,
    branch_names: ["branch"],
    vehicle_tooltip: %VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: "route_id"}},
    row_content_template: "_line_page_stop_info.html",
    reverse_direction_all_stops: [%Stop{id: "other stop"}],
    expanded: nil
  }

  describe "stop_bubble_row_params/2" do
    test "flattens the assigns into the map needed for the stop bubbles for a particular row" do
      params = stop_bubble_row_params(@assigns)

      assert [
               %StopBubble.Params{
                 render_type: :terminus,
                 class: "terminus",
                 route_id: nil,
                 route_type: 1,
                 direction_id: 1,
                 vehicle_tooltip: %VehicleTooltip{},
                 merge_indent: nil,
                 show_line?: true
               }
             ] = params
    end

    test "sets to render_type to :empty and the class to :line when a :line bubble is passed in" do
      assigns = %{@assigns | bubbles: [{"branch", :line}]}

      [params] = stop_bubble_row_params(assigns, true)

      assert params.render_type == :empty
      assert params.class == "line"
      assert params.show_line?
    end

    test "sets the render_type to :empty and the class to :merge on the second merge bubble" do
      assigns = %{@assigns | bubbles: [{"branch", :merge}, {"branch", :merge}]}

      params = stop_bubble_row_params(assigns, true)

      assert [
               %StopBubble.Params{render_type: :merge, class: "merge"},
               %StopBubble.Params{render_type: :empty, class: "merge"}
             ] = params
    end

    test "does not provide a vehicle_tooltip is no vehicle_tooltip is present" do
      assigns = %{@assigns | vehicle_tooltip: nil}

      [params] = stop_bubble_row_params(assigns, true)

      refute params.vehicle_tooltip
    end

    test "only provides a tooltip for the bubble whose branch matches the vehicle's route_id on the green line" do
      assigns = %{
        @assigns
        | bubbles: [
            {"Green-B", :stop},
            {"Green-C", :stop},
            {"Green-D", :stop},
            {"Green-E", :stop}
          ],
          route: %Route{id: "Green"},
          vehicle_tooltip: %VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: "Green-D"}}
      }

      tooltips =
        assigns
        |> stop_bubble_row_params
        |> Enum.map(& &1.vehicle_tooltip)

      assert [nil, nil, %VehicleTooltip{}, nil] = tooltips
    end

    test "does not provide a vehicle_tooltip if the render_type is :line" do
      assigns = %{@assigns | bubbles: [{"branch", :line}]}

      [params] = stop_bubble_row_params(assigns)

      refute params.vehicle_tooltip
    end

    test "sets show_line? to false if the render_type is :empty" do
      assigns = %{@assigns | bubbles: [{"branch", :empty}]}

      [params] = stop_bubble_row_params(assigns, true)

      assert params.render_type == :empty
      assert params.class == "empty"
      refute params.show_line?
    end

    test "sets show_line? false if the render_type is :terminus and the stop is not the first stop" do
      assigns = %{@assigns | bubbles: [{"branch", :terminus}]}

      [params] = stop_bubble_row_params(assigns, false)

      refute params.show_line?
    end

    test "sets content to the letter of the green line branch if the route is green" do
      assigns = %{@assigns | route: %Route{id: "Green", type: 1}, bubbles: [{"Green-B", :stop}]}

      [params] = stop_bubble_row_params(assigns, false)

      assert params.content == "B"
    end

    test "sets content to the empty string for any other route id" do
      [params] = stop_bubble_row_params(@assigns, false)

      assert params.content == ""
    end
  end

  describe "Green Line bubble params" do
    test "at copley when direction is 0" do
      assigns = %{
        @assigns
        | bubbles: Enum.map(["B", "C", "D", "E"], &{"Green-" <> &1, :stop}),
          direction_id: 0,
          route: %Route{id: "Green", type: 0},
          stop: %RouteStop{id: "place-coecl", branch: nil}
      }

      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop"
    end

    test "at copley when direction is 1" do
      assigns = %{
        @assigns
        | bubbles: Enum.map(["B", "C", "D", "E"], &{"Green-" <> &1, :stop}),
          direction_id: 1,
          route: %Route{id: "Green", type: 0},
          stop: %RouteStop{id: "place-coecl", branch: nil}
      }

      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop"
    end

    test "for E line branch stops in either direction" do
      assigns = %{
        @assigns
        | bubbles: Enum.map(["B", "C", "D", "E"], &{"Green-" <> &1, :stop}),
          direction_id: 0,
          route: %Route{id: "Green", type: 0},
          stop: %RouteStop{id: "place-prmnl", branch: "Green-E"}
      }

      assert [b_line, c_line, d_line, e_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
      assert e_line.class == "stop"

      assert [b_line_1, c_line_1, d_line_1, e_line_1] =
               stop_bubble_row_params(%{assigns | direction_id: 1})

      assert b_line_1.class == "stop"
      assert c_line_1.class == "stop"
      assert d_line_1.class == "stop"
      assert e_line_1.class == "stop"
    end

    test "all kenmore bubbles are solid when direction_id is 1" do
      assigns = %{
        @assigns
        | bubbles: Enum.map(["B", "C", "D"], &{"Green-" <> &1, :stop}),
          direction_id: 1,
          route: %Route{id: "Green", type: 0},
          stop: %RouteStop{id: "place-kencl", branch: nil}
      }

      assert [b_line, c_line, d_line] = stop_bubble_row_params(assigns)
      assert b_line.class == "stop"
      assert c_line.class == "stop"
      assert d_line.class == "stop"
    end

    test "schedule view expand link is solid" do
      assigns = %{
        @assigns
        | bubbles: [{"Green-E", :line}],
          stop: nil,
          route: %Route{id: "Green", type: 1},
          direction_id: 1,
          conn: "conn",
          branch_names: ["Green-E"],
          vehicle_tooltip: %VehicleTooltip{vehicle: %Vehicles.Vehicle{route_id: "Green"}},
          expanded: nil
      }

      assert [expand_link] = stop_bubble_row_params(assigns)
      assert expand_link.class == "line"
    end

    test "Expand link lists number of collapsed stops" do
      assigns = %{
        bubbles: [{"Green-E", :line}],
        target_id: "target-id",
        intermediate_stop_count: 11,
        branch_name: "Green-E",
        branch_display: "Green-E branch",
        route: %Route{id: "Green-E"},
        vehicle_tooltip: nil,
        expanded: nil,
        conn: %{query_params: %{}, request_path: ""}
      }

      rendered = "_stop_list_expand_link.html" |> ScheduleView.render(assigns) |> safe_to_string()

      assert rendered =~ "11"
    end

    test "Expand link displays branch_display as link text" do
      assigns = %{
        bubbles: [{"Braintree", :line}],
        target_id: "target-id",
        intermediate_stop_count: 9,
        branch_name: "Braintree",
        branch_display: "Braintree branch",
        route: %Route{id: "Red"},
        vehicle_tooltip: nil,
        expanded: nil,
        conn: %{query_params: %{}, request_path: ""}
      }

      rendered = "_stop_list_expand_link.html" |> ScheduleView.render(assigns) |> safe_to_string()

      assert rendered =~ "Braintree branch"
    end

    test "Expand link starts as expanded when the expanded is true" do
      assigns = %{
        bubbles: [{"Braintree", :line}],
        target_id: "target-id",
        intermediate_stop_count: 9,
        branch_name: "Braintree",
        branch_display: "Braintree branch",
        route: %Route{id: "Red"},
        vehicle_tooltip: nil,
        expanded: true,
        conn: %{query_params: %{}, request_path: ""}
      }

      rendered = "_stop_list_expand_link.html" |> ScheduleView.render(assigns) |> safe_to_string()

      branch_stop = Floki.find(rendered, ".route-branch-stop")

      assert Floki.attribute(branch_stop, "class") == ["route-branch-stop expanded"]
    end
  end

  describe "rendering stop list rows" do
    @trunk [
      {[{nil, :terminus}],
       %RouteStop{name: "Broadway", id: "broadway", branch: nil}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()},
      {[{nil, :stop}],
       %RouteStop{name: "Andrew", id: "andrew", branch: nil}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()},
      {[{nil, :merge}],
       %RouteStop{name: "JFK/Umass", id: "jfk-umass", branch: nil}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()}
    ]
    @braintree [
      {[{"Ashmont", :line}, {"Braintree", :stop}],
       %RouteStop{name: "North Quincy", id: "north-quincy", branch: "Braintree"}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()},
      {[{"Ashmont", :line}, {"Braintree", :terminus}],
       %RouteStop{name: "Wollaston", id: "wollaston", branch: "Braintree"}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()}
    ]
    @ashmont [
      {[{"Ashmont", :stop}, {"Braintree", :empty}],
       %RouteStop{name: "Savin Hill", id: "savin-hill", branch: "Ashmont"}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()},
      {[{"Ashmont", :terminus}, {"Braintree", :empty}],
       %RouteStop{name: "Fields Corner", id: "fields-corner", branch: "Ashmont"}
       |> RouteStop.fetch_stop_features()
       |> RouteStop.fetch_zone()}
    ]
    @assigns %{
      all_stops: @trunk ++ @braintree ++ @ashmont,
      conn: %Plug.Conn{query_params: %{}},
      route: %Route{id: "Red", name: "Red Line", type: 1},
      direction_id: 0,
      vehicle_tooltips: %{},
      expanded: nil,
      reverse_direction_all_stops: [],
      time_data_by_stop: %{}
    }

    test "splits the stops up into groups based on the branch" do
      stops =
        @assigns.all_stops
        |> chunk_branches()
        |> Enum.map(fn chunk ->
          Enum.map(chunk, fn {_bubbles, %RouteStop{name: name}} -> name end)
        end)

      assert stops == [
               ["Broadway", "Andrew", "JFK/Umass"],
               ["North Quincy", "Wollaston"],
               ["Savin Hill", "Fields Corner"]
             ]
    end

    test "extracts the last row as the expand row for direction-id = 0" do
      expected = {List.last(@braintree), -1, Enum.take(@braintree, 1)}
      assert separate_collapsible_rows(@braintree, 0) == expected
    end

    test "extracts the first row as the expand row for direction-id = 1" do
      expected = {List.first(@braintree), 0, Enum.drop(@braintree, 1)}
      assert separate_collapsible_rows(@braintree, 1) == expected
    end

    test "renders a stop row" do
      [row | _] = @trunk

      html =
        row
        |> render_row(@assigns)
        |> safe_to_string

      assert html =~ "route-branch-stop-bubble"
    end

    test "recombines expand and collapsible rows when branch is nil" do
      separated_rows = separate_collapsible_rows(@trunk, 0)

      html =
        separated_rows
        |> merge_rows(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary()

      refute html =~ "id =\"branch-braintree\""
      refute html =~ "id =\"branch-ashmont\""
      refute html =~ "class=\"collapse\""

      names =
        html
        |> Floki.find(".route-branch-stop-name")
        |> Enum.map(fn {_elem, _attrs, [{_e, _a, [name]}]} -> String.trim(name) end)

      assert names == ["Broadway", "Andrew", "JFK/​Umass"]
    end

    test "collapses branch when it is not nil and there is more than one intermediate stop" do
      braintree = [
        {[{"Ashmont", :line}, {"Braintree", :stop}],
         %RouteStop{name: "Quincy Center", id: "quincy-center", branch: "Braintree"}
         |> RouteStop.fetch_zone()
         |> RouteStop.fetch_stop_features()},
        {[{"Ashmont", :line}, {"Braintree", :stop}],
         %RouteStop{name: "North Quincy", id: "north-quincy", branch: "Braintree"}
         |> RouteStop.fetch_zone()
         |> RouteStop.fetch_stop_features()},
        {[{"Ashmont", :line}, {"Braintree", :terminus}],
         %RouteStop{name: "Wollaston", id: "wollaston", branch: "Braintree"}
         |> RouteStop.fetch_zone()
         |> RouteStop.fetch_stop_features()}
      ]

      all_stops = @trunk ++ braintree ++ @ashmont

      separated_rows = separate_collapsible_rows(braintree, 0)

      assigns = %{@assigns | all_stops: all_stops}

      html =
        separated_rows
        |> merge_rows(assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary()

      assert Enum.count(Floki.find(html, ".collapse")) == 1
      assert Enum.count(Floki.find(html, "#branch-braintree")) == 1
      assert Enum.empty?(Floki.find(html, "#branch-ashmont"))

      names =
        html
        |> Floki.find(".route-branch-stop-name")
        |> Enum.map(fn {_elem, _attrs, [{_e, _a, [name]}]} -> String.trim(name) end)

      assert names == ["Quincy Center", "North Quincy", "Wollaston"]
    end

    test "does not collapse the branch when there fewer than two intermediate stops" do
      separated_rows = separate_collapsible_rows(@braintree, 0)

      html =
        separated_rows
        |> merge_rows(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary()

      assert Enum.empty?(Floki.find(html, ".collapse"))
      assert Enum.empty?(Floki.find(html, "#branch-braintree"))
      assert Enum.empty?(Floki.find(html, "#branch-ashmont"))

      names =
        html
        |> Floki.find(".route-branch-stop-name")
        |> Enum.map(fn {_elem, _attrs, [{_e, _a, [name]}]} -> String.trim(name) end)

      assert names == ["North Quincy", "Wollaston"]
    end
  end

  describe "display_departure_range/1" do
    test "with :no_service, returns No Service" do
      result = display_departure_range(:no_service)
      assert result == "No Service"
    end

    test "with times, displays them formatted" do
      result =
        %Departures{
          first_departure: ~N[2017-02-27 06:15:00],
          last_departure: ~N[2017-02-28 01:04:00]
        }
        |> display_departure_range
        |> IO.iodata_to_binary()

      assert result == "06:15A-01:04A"
    end
  end

  describe "display_map_link?/1" do
    test "is true for subway and ferry" do
      assert display_map_link?(4) == true
    end

    test "is false for subway, bus and commuter rail" do
      assert display_map_link?(0) == false
      assert display_map_link?(3) == false
      assert display_map_link?(2) == false
    end
  end

  describe "trip_link/4" do
    test "trip link for non-matching trip", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, false, "2") == "/?trip=2#2"
    end

    test "trip link for matching, un-chosen stop", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, false, "1") == "/?trip=1#1"
    end

    test "trip link for matching, chosen stop", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      assert trip_link(conn, @trip_info, true, "1") == "/?trip=#1"
    end
  end

  describe "display_expand_link?/1" do
    test "Do not display expansion link when there are no steps" do
      refute display_expand_link?([])
    end

    test "Do not display expansion link when there is only a single step" do
      refute display_expand_link?(["Single Step"])
    end

    test "Display link when there are more than 1 step" do
      assert display_expand_link?(["Step 1", "Step 2"])
      assert display_expand_link?(["Step 1", "Step 2", "Step 3"])
    end
  end

  describe "step_bubble_attributes/3" do
    test "returns id and class when there is more than one intermediate step" do
      assert step_bubble_attributes(["Step 1", "Step 2"], "target", false) == [
               id: "target",
               class: "collapse stop-list"
             ]
    end

    test "returns empty when there is one or less intermediate steps" do
      assert step_bubble_attributes([], "target", false) == []
      assert step_bubble_attributes(["Step 1"], "target", false) == []
    end

    test "returns an expanded list when expanded is true" do
      assert step_bubble_attributes(["Step 1", "Step 2"], "target", true) == [
               id: "target",
               class: "collapse stop-list in"
             ]
    end
  end

  describe "_cms_teasers.html" do
    test "renders featured content and news", %{conn: conn} do
      assert {news, [featured | _]} =
               [route_id: "Red", sidebar: 1]
               |> Repo.teasers()
               |> Enum.split_with(&(&1.type === :news_entry))

      refute Enum.empty?(news)

      rendered =
        "_cms_teasers.html"
        |> ScheduleView.render(
          featured_content: featured,
          news: news,
          conn: conn,
          teaser_class: "teaser-class",
          news_class: "news-class"
        )
        |> safe_to_string()

      assert rendered =~ featured.image.url
      assert rendered =~ featured.image.alt
      assert rendered =~ featured.title
      assert rendered =~ "teaser-class"
      assert rendered =~ "news-class"

      for item <- news do
        assert rendered =~ item.title
        assert rendered =~ Timex.format!(item.date, "{Mshort}")
      end
    end

    test "renders nothing when there is no content" do
      rendered =
        "_cms_teasers.html"
        |> ScheduleView.render(featured_content: nil, news: [])
        |> safe_to_string()

      assert rendered == "\n"
    end
  end
end
