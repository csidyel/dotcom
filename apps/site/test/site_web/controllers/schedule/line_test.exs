defmodule SiteWeb.ScheduleController.LineTest do
  use SiteWeb.ConnCase, async: true
  import SiteWeb.ScheduleController.Line.Helpers
  import SiteWeb.ScheduleController.Line.DiagramHelpers
  alias Plug.Conn
  alias Routes.Route
  alias Services.Service
  alias Stops.{RouteStop, RouteStops}

  doctest SiteWeb.ScheduleController.Line

  @deps %SiteWeb.ScheduleController.Line.Dependencies{}

  @thirtynine_services [
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Weekday schedule",
      end_date: ~D[2020-03-13],
      id: "BUS120-3-Wdy-02",
      name: "Weekday",
      removed_dates: [
        "2020-01-20",
        "2020-02-17",
        "2020-02-18",
        "2020-02-19",
        "2020-02-20",
        "2020-02-21"
      ],
      removed_dates_notes: %{
        "2020-01-20" => "Martin Luther King Day",
        "2020-02-17" => "Washington's Birthday",
        "2020-02-18" => nil,
        "2020-02-19" => nil,
        "2020-02-20" => nil,
        "2020-02-21" => nil
      },
      start_date: ~D[2020-01-02],
      type: :weekday,
      typicality: :typical_service,
      valid_days: [1, 2, 3, 4, 5]
    },
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Weekday schedule",
      end_date: ~D[2020-03-13],
      id: "BUS120-Z-Wdy-02",
      name: "Weekday",
      removed_dates: [
        "2020-01-20",
        "2020-02-17",
        "2020-02-18",
        "2020-02-19",
        "2020-02-20",
        "2020-02-21"
      ],
      removed_dates_notes: %{
        "2020-01-20" => "Martin Luther King Day",
        "2020-02-17" => "Washington's Birthday",
        "2020-02-18" => nil,
        "2020-02-19" => nil,
        "2020-02-20" => nil,
        "2020-02-21" => nil
      },
      start_date: ~D[2020-01-02],
      type: :weekday,
      typicality: :typical_service,
      valid_days: [1, 2, 3, 4, 5]
    },
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Saturday schedule",
      end_date: ~D[2019-12-21],
      id: "BUS419-3-Sa-02",
      name: "Saturday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-21],
      type: :saturday,
      typicality: :typical_service,
      valid_days: [6]
    },
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Saturday schedule",
      end_date: ~D[2019-12-21],
      id: "BUS419-E-Sa-02",
      name: "Saturday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-21],
      type: :saturday,
      typicality: :typical_service,
      valid_days: [6]
    },
    %Service{
      added_dates: ["2019-12-25", "2020-01-01"],
      added_dates_notes: %{
        "2019-12-25" => "Christmas Day",
        "2020-01-01" => "New Year's Day"
      },
      description: "Holiday (Sunday schedule)",
      end_date: ~D[2020-01-01],
      id: "ChristmasDay-NewYearsDay",
      name: "Holiday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-25],
      type: :sunday,
      typicality: :holiday_service,
      valid_days: []
    },
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Weekday schedule",
      end_date: ~D[2019-12-20],
      id: "FallWeekday",
      name: "Weekday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-20],
      type: :weekday,
      typicality: :typical_service,
      valid_days: [5]
    },
    %Service{
      added_dates: ["2020-01-20", "2020-02-17"],
      added_dates_notes: %{
        "2020-01-20" => "Martin Luther King Day",
        "2020-02-17" => "Washington's Birthday"
      },
      description: "Holiday (Saturday schedule)",
      end_date: ~D[2020-02-17],
      id: "MartinLutherKingDay-WashingtonsBirthday",
      name: "Holiday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2020-01-20],
      type: :saturday,
      typicality: :holiday_service,
      valid_days: []
    },
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Saturday schedule",
      end_date: ~D[2020-03-14],
      id: "WinterSaturday",
      name: "Saturday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-28],
      type: :saturday,
      typicality: :typical_service,
      valid_days: [6]
    },
    %Service{
      added_dates: [],
      added_dates_notes: %{},
      description: "Sunday schedule",
      end_date: ~D[2020-03-08],
      id: "WinterSunday",
      name: "Sunday",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-22],
      type: :sunday,
      typicality: :typical_service,
      valid_days: '\a'
    },
    %Service{
      added_dates: ["2020-02-18", "2020-02-19", "2020-02-20", "2020-02-21"],
      added_dates_notes: %{
        "2020-02-18" => nil,
        "2020-02-19" => nil,
        "2020-02-20" => nil,
        "2020-02-21" => nil
      },
      description: "Weekday schedule (no school)",
      end_date: ~D[2019-12-31],
      id: "WinterWeekday",
      name: "Weekday (no school)",
      removed_dates: [],
      removed_dates_notes: %{},
      start_date: ~D[2019-12-23],
      type: :weekday,
      typicality: :typical_service,
      valid_days: [1, 2, 4, 5]
    }
  ]

  @fourtwofour_services [
    %{
      __struct__: Services.Service,
      added_dates: [],
      added_dates_notes: %{},
      description: "Weekday schedule",
      end_date: ~D[2020-03-13],
      id: "WinterWeekday",
      name: "Weekday",
      removed_dates: [
        "2020-01-20",
        "2020-02-17",
        "2020-02-18",
        "2020-02-19",
        "2020-02-20",
        "2020-02-21"
      ],
      removed_dates_notes: %{
        "2020-01-20" => "Martin Luther King Day",
        "2020-02-17" => "Washington's Birthday",
        "2020-02-18" => nil,
        "2020-02-19" => nil,
        "2020-02-20" => nil,
        "2020-02-21" => nil
      },
      service_date: ~D[2020-01-20],
      start_date: ~D[2020-01-09],
      type: :weekday,
      typicality: :typical_service,
      valid_days: [1, 2, 3, 4, 5]
    }
  ]

  def get_error_stop_list(_, _, _), do: {:error, "error"}

  describe "get_branches" do
    test "returns RouteStops for all green line branches in reverse order when direction is 0" do
      shapes = get_route_shapes("Green", 0)
      route_stops = get_route_stops("Green", 0, @deps.stops_by_route_fn)
      result = get_branches(shapes, route_stops, %Routes.Route{id: "Green"}, 0)
      assert Enum.map(result, & &1.branch) == ["Green-E", "Green-D", "Green-C", "Green-B"]
    end

    test "Does not return branches when route has no trips in given direction", %{conn: conn} do
      conn = get(conn, line_path(conn, :show, "195", direction_id: 0))
      assert conn.assigns.branches == []
    end

    test "handle error for all green line branches" do
      shapes = get_route_shapes("Green", 0)
      route_stops = get_route_stops("Green", 0, &get_error_stop_list/3)
      result = get_branches(shapes, route_stops, %Routes.Route{id: "Green"}, 0)
      assert result == []
    end

    test "handle error for all red line branches" do
      shapes = get_route_shapes("Red", 0)
      route_stops = get_route_stops("Red", 0, &get_error_stop_list/3)
      result = get_branches(shapes, route_stops, %Routes.Route{id: "Red"}, 0)
      assert result == []
    end
  end

  describe "build_stop_list/2 for Green Line" do
    defp stop_id({_branches, stop_id}), do: stop_id
    defp branches({branches, _stop_id}), do: branches

    test "direction 0 returns a list of all stops in order from east to west" do
      route_stops = get_route_stops("Green", 0, @deps.stops_by_route_fn)

      stops =
        "Green"
        |> get_route_shapes(0)
        |> get_branches(route_stops, %Routes.Route{id: "Green"}, 0)
        |> build_stop_list(0)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      for {id, idx} <- [
            {"place-lech", 0},
            {"place-north", 2},
            {"place-gover", 4},
            {"place-pktrm", 5},
            {"place-coecl", 8},
            {"place-hsmnl", 19},
            {"place-river", 34},
            {"place-clmnl", 47},
            {"place-lake", 65}
          ] do
        assert stops |> Enum.at(idx) |> elem(1) == id
      end
    end

    test "direction 0 returns the correct number of bubbles for each stop" do
      route_stops = get_route_stops("Green", 0, @deps.stops_by_route_fn)

      stops =
        "Green"
        |> get_route_shapes(0)
        |> get_branches(route_stops, %Routes.Route{id: "Green"}, 0)
        |> build_stop_list(0)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      [four, three, two, one] =
        Enum.chunk_by(stops, fn {branches, _stop} -> Enum.count(branches) end)

      assert Enum.each(four, &(Enum.count(branches(&1)) == 4))
      assert stop_id(List.first(four)) == "place-lech"
      assert stop_id(List.last(four)) == "place-hsmnl"

      assert Enum.each(three, &(Enum.count(branches(&1)) == 3))
      assert stop_id(List.first(three)) == "place-hymnl"
      assert stop_id(List.last(three)) == "place-river"

      assert Enum.each(two, &(Enum.count(branches(&1)) == 2))
      assert stop_id(List.first(two)) == "place-smary"
      assert stop_id(List.last(two)) == "place-clmnl"

      assert Enum.each(one, &(Enum.count(branches(&1)) == 1))
      assert stop_id(List.first(one)) == "place-bland"
      assert stop_id(List.last(one)) == "place-lake"
    end

    test "direction 1 returns a list of all stops in order from west to east" do
      route_stops = get_route_stops("Green", 0, @deps.stops_by_route_fn)

      stops =
        "Green"
        |> get_route_shapes(1)
        |> get_branches(route_stops, %Routes.Route{id: "Green"}, 1)
        |> build_stop_list(1)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      for {id, idx} <- [
            {"place-lech", 65},
            {"place-north", 63},
            {"place-gover", 61},
            {"place-pktrm", 60},
            {"place-coecl", 57},
            {"place-hsmnl", 46},
            {"place-river", 31},
            {"place-clmnl", 18},
            {"place-lake", 0}
          ] do
        assert stops |> Enum.at(idx) |> elem(1) == id
      end
    end

    test "direction 1 returns the correct number of bubbles for each stop" do
      route_stops = get_route_stops("Green", 0, @deps.stops_by_route_fn)

      stops =
        "Green"
        |> get_route_shapes(1)
        |> get_branches(route_stops, %Routes.Route{id: "Green"}, 1)
        |> build_stop_list(1)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert [one, two, three, four] =
               Enum.chunk_by(stops, fn {branches, _stop} -> Enum.count(branches) end)

      assert stop_id(List.first(one)) == "place-lake"
      assert stop_id(List.last(one)) == "place-bland"
      assert stop_id(List.first(two)) == "place-clmnl"
      assert stop_id(List.last(two)) == "place-smary"
      assert stop_id(List.first(three)) == "place-river"
      assert stop_id(List.last(three)) == "place-hymnl"
      assert stop_id(List.first(four)) == "place-hsmnl"
      assert stop_id(List.last(four)) == "place-lech"
    end
  end

  describe "build_stop_list/2 for branched non-Green routes" do
    test "Red outbound" do
      route_stops = get_route_stops("Red", 0, @deps.stops_by_route_fn)

      stops =
        "Red"
        |> get_route_shapes(0)
        |> get_branches(route_stops, %Routes.Route{id: "Red"}, 0)
        |> build_stop_list(0)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      for {id, idx} <- [
            {"place-alfcl", 0},
            {"place-jfk", 12},
            {"place-brntn", -5},
            {"place-asmnl", -1}
          ] do
        assert stops |> Enum.at(idx) |> elem(1) == id
      end
    end

    test "outbound returns the correct number of bubbles for each stop" do
      route_stops = get_route_stops("Red", 0, @deps.stops_by_route_fn)

      stops =
        "Red"
        |> get_route_shapes(0)
        |> get_branches(route_stops, %Routes.Route{id: "Red"}, 0)
        |> build_stop_list(0)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      [one, two, another_one] =
        Enum.chunk_by(stops, fn {branches, _stop} -> Enum.count(branches) end)

      assert Enum.each(one, &(Enum.count(branches(&1)) == 1))
      assert stop_id(List.first(one)) == "place-alfcl"
      assert stop_id(List.last(one)) == "place-andrw"

      assert Enum.each(two, &(Enum.count(branches(&1)) == 2))
      assert stop_id(List.first(two)) == "place-jfk"
      assert stop_id(List.last(two)) == "place-brntn"

      assert Enum.each(another_one, &(Enum.count(branches(&1)) == 1))
      assert stop_id(List.first(another_one)) == "place-shmnl"
      assert stop_id(List.last(another_one)) == "place-asmnl"
    end

    test "Red inbound" do
      route_stops = get_route_stops("Red", 0, @deps.stops_by_route_fn)

      stops =
        "Red"
        |> get_route_shapes(1)
        |> get_branches(route_stops, %Routes.Route{id: "Red"}, 1)
        |> build_stop_list(1)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      for {id, idx} <- [
            {"place-alfcl", -1},
            {"place-jfk", -13},
            {"place-brntn", 4},
            {"place-asmnl", 0}
          ] do
        assert stops |> Enum.at(idx) |> elem(1) == id
      end
    end

    test "inbound returns the correct number of bubbles for each stop" do
      route_stops = get_route_stops("Red", 0, @deps.stops_by_route_fn)

      stops =
        "Red"
        |> get_route_shapes(1)
        |> get_branches(route_stops, %Routes.Route{id: "Red"}, 1)
        |> build_stop_list(1)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      [another_one, two, one] =
        Enum.chunk_by(stops, fn {branches, _stop} -> Enum.count(branches) end)

      assert Enum.each(another_one, &(Enum.count(branches(&1)) == 1))
      assert stop_id(List.first(another_one)) == "place-asmnl"
      assert stop_id(List.last(another_one)) == "place-shmnl"

      assert Enum.each(two, &(Enum.count(branches(&1)) == 2))
      assert stop_id(List.first(two)) == "place-brntn"
      assert stop_id(List.last(two)) == "place-jfk"

      assert Enum.each(one, &(Enum.count(branches(&1)) == 1))
      assert stop_id(List.first(one)) == "place-andrw"
      assert stop_id(List.last(one)) == "place-alfcl"
    end

    test "CR-Providence outbound" do
      route_stops = get_route_stops("CR-Providence", 0, @deps.stops_by_route_fn)

      stops =
        "CR-Providence"
        |> get_route_shapes(0)
        |> get_branches(route_stops, %Routes.Route{id: "CR-Providence"}, 0)
        |> build_stop_list(0)
        |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      for {id, idx} <- [
            {"place-sstat", 0},
            {"place-NEC-2139", 5},
            {"place-SB-0189", 7},
            {"place-NEC-1659", 14}
          ] do
        assert stops |> Enum.at(idx) |> elem(1) == id
      end
    end

    # test "CR-Providence outbound has correct number of bubbles" do
    #   route_stops = get_route_stops("CR-Providence", 0, @deps.stops_by_route_fn)
    #   stops =
    #     "CR-Providence"
    #     |> get_route_shapes(0)
    #     |> get_branches(route_stops, %Routes.Route{id: "CR-Providence"}, 0)
    #     |> build_stop_list(0)
    #     |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

    #   [one, two, another_one] = Enum.chunk_by(stops, fn {branches, _stop} -> Enum.count(branches) end)
    #   assert Enum.each(one, &(Enum.count(branches(&1)) == 1))
    #   assert stop_id(List.first(one)) == "place-sstat"
    #   assert stop_id(List.last(one)) == "Route 128"

    #   assert Enum.each(two, &(Enum.count(branches(&1)) == 2))
    #   assert stop_id(List.first(two)) == "Canton Junction"
    #   assert stop_id(List.last(two)) == "Stoughton"

    #   assert Enum.each(another_one, &(Enum.count(branches(&1)) == 1))
    #   assert stop_id(List.first(another_one)) == "Sharon"
    #   assert stop_id(List.last(another_one)) == "Wickford Junction"
    # end

    # test "CR-Providence inbound" do
    #   route_stops = get_route_stops("CR-Providence", 1, @deps.stops_by_route_fn)
    #   stops =
    #     "CR-Providence"
    #     |> get_route_shapes(1)
    #     |> get_branches(route_stops, %Routes.Route{id: "CR-Providence"}, 1)
    #     |> build_stop_list(1)
    #     |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

    #   for {id, idx} <- [{"place-sstat", 14}, {"Canton Junction", 9}, {"Stoughton", 7}, {"Wickford Junction", 0}] do
    #     assert stops |> Enum.at(idx) |> elem(1) == id
    #   end
    # end

    # test "CR-Providence inboung has correct number of bubbles" do
    #   route_stops = get_route_stops("CR-Providence", 1, @deps.stops_by_route_fn)
    #   stops =
    #     "CR-Providence"
    #     |> get_route_shapes(1)
    #     |> get_branches(route_stops, %Routes.Route{id: "CR-Providence"}, 1)
    #     |> build_stop_list(1)
    #     |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

    #   [another_one, two, one] = Enum.chunk_by(stops, fn {branches, _stop} -> Enum.count(branches) end)
    #   assert Enum.each(another_one, &(Enum.count(branches(&1)) == 1))
    #   assert stop_id(List.first(another_one)) == "Wickford Junction"
    #   assert stop_id(List.last(another_one)) == "Sharon"

    #   assert Enum.each(two, &(Enum.count(branches(&1)) == 2))
    #   assert stop_id(List.first(two)) == "Stoughton"
    #   assert stop_id(List.last(two)) == "Canton Junction"

    #   assert Enum.each(one, &(Enum.count(branches(&1)) == 1))
    #   assert stop_id(List.first(one)) == "Route 128"
    #   assert stop_id(List.last(one)) == "place-sstat"
    # end
  end

  describe "stop_bubble_type/2" do
    test "copley" do
      stop = %RouteStop{id: "place-coecl"}
      assert stop_bubble_type("Green-B", stop) == {"Green-B", :stop}
      assert stop_bubble_type("Green-C", stop) == {"Green-C", :stop}
      assert stop_bubble_type("Green-D", stop) == {"Green-D", :stop}
      assert stop_bubble_type("Green-E", stop) == {"Green-E", :stop}
    end
  end

  describe "build_branched_stop" do
    test "lechmere" do
      stop = %RouteStop{id: "place-lech"}
      branches = {nil, GreenLine.branch_ids()}

      bubbles = [
        {"Green-B", :empty},
        {"Green-C", :empty},
        {"Green-D", :empty},
        {"Green-E", :terminus}
      ]

      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "park" do
      stop = %RouteStop{id: "place-pktrm"}
      branches = {nil, GreenLine.branch_ids()}

      bubbles = [
        {"Green-B", :terminus},
        {"Green-C", :stop},
        {"Green-D", :stop},
        {"Green-E", :stop}
      ]

      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "copley" do
      stop = %RouteStop{id: "place-coecl"}
      branches = {nil, GreenLine.branch_ids()}
      bubbles = [{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}]
      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "heath st" do
      assert GreenLine.terminus?("place-hsmnl", "Green-E")
      stop = %RouteStop{id: "place-hsmnl", branch: "Green-E", is_terminus?: true}
      branches = {nil, GreenLine.branch_ids()}

      bubbles = [
        {"Green-B", :line},
        {"Green-C", :line},
        {"Green-D", :line},
        {"Green-E", :terminus}
      ]

      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "a terminus that's not on a branch is always a terminus" do
      stop = %RouteStop{id: "new", branch: nil, is_terminus?: true}
      assert build_branched_stop({stop, true}, [], {nil, []}) == [{[{nil, :terminus}], stop}]
      assert build_branched_stop({stop, false}, [], {nil, []}) == [{[{nil, :terminus}], stop}]
    end

    test "non-terminus in unbranched stops is a merge stop when it's first or last in list" do
      new_stop = %RouteStop{id: "new"}
      result = build_branched_stop({new_stop, true}, [], {nil, ["branch 1", "branch 2"]})
      assert result == [{[{"branch 1", :merge}, {"branch 2", :merge}], new_stop}]
    end

    test "unbranched stops that aren't first or last in list are just :stop" do
      new_stop = %RouteStop{id: "new"}
      result = build_branched_stop({new_stop, false}, [], {nil, []})
      assert result == [{[{nil, :stop}], new_stop}]
    end

    test "branched terminus includes :terminus in stop bubbles" do
      new_stop = %RouteStop{id: "new", branch: "branch 1", is_terminus?: true}
      result = build_branched_stop({new_stop, false}, [], {"branch 1", ["branch 1", "branch 2"]})
      assert result == [{[{"branch 1", :terminus}, {"branch 2", :line}], new_stop}]
    end
  end

  describe "build_branched_stop_list" do
    test "returns stops in reverse order for both directions when branch is nil" do
      stops =
        ["first", "middle", "last"]
        |> Util.EnumHelpers.with_first_last()
        |> Enum.map(fn {stop_id, is_terminus?} ->
          %RouteStop{id: stop_id, is_terminus?: is_terminus?}
        end)

      outbound = build_branched_stop_list(%RouteStops{branch: nil, stops: stops}, {[], []})
      inbound = build_branched_stop_list(%RouteStops{branch: nil, stops: stops}, {[], []})
      assert outbound == inbound
      assert {[last, middle, first], []} = outbound
      assert last == {[{nil, :terminus}], %RouteStop{id: "last", is_terminus?: true}}
      assert middle == {[{nil, :stop}], %RouteStop{id: "middle", is_terminus?: false}}
      assert first == {[{nil, :terminus}], %RouteStop{id: "first", is_terminus?: true}}
    end
  end

  describe "services" do
    test "determines a single, default service for route and date", %{conn: conn} do
      conn =
        conn
        |> assign(:services_fn, fn _ -> @thirtynine_services end)
        |> get(line_path(conn, :show, "39"))

      services_for_route = conn.assigns.schedule_page_data.services
      default_service = Enum.filter(services_for_route, &(&1.default_service? === true))

      assert length(default_service) == 1
    end

    test "uses the first service as a default if no services are valid", %{conn: conn} do
      conn =
        conn
        |> assign(:date_time, ~D[2020-01-20])
        |> assign(:services_fn, fn _ -> @fourtwofour_services end)
        |> get(line_path(conn, :show, "424"))

      services_for_route = conn.assigns.schedule_page_data.services
      default_services = Enum.filter(services_for_route, &(&1.default_service? === true))

      assert length(default_services) == 1
      assert default_services = [%{id: "WinterWeekday1"}]
    end
  end

  describe "line diagram endpoint" do
    test "renders", %{conn: conn} do
      conn =
        conn
        |> get(line_path(conn, :line_diagram_api, "39"))

      assert html_response(conn, 200) =~ "Forest Hills"
    end
  end

  describe "get_shuttle_data" do
    test "returns empty data when given a route and a date_time without shuttle service", %{
      conn: conn
    } do
      conn =
        conn
        |> Conn.assign(:route, %Route{id: "Red", type: 1})
        |> Conn.assign(:date_time, ~N[2019-11-25T12:00:00])

      expected = %Site.ShuttleDiversion{alerts: [], shapes: [], stops: []}
      data = get_shuttle_data(conn)
      assert data == expected
    end
  end
end
