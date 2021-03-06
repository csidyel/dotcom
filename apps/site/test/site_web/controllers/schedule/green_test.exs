defmodule SiteWeb.ScheduleController.GreenTest do
  alias Routes.Repo

  use SiteWeb.ConnCase, async: true

  import SiteWeb.ScheduleController.Green

  @moduletag :external

  @green_line Repo.green_line()

  describe "schedule_path/3" do
    test "renders line tab without redirect when query_params doesn't include :tab", %{conn: conn} do
      conn = get(conn, schedule_path(conn, :show, "Green"))

      assert conn.status == 200

      assert conn.assigns.tab == "line"
    end

    test ~s(renders trip_view tab without redirecting when query params = %{tab => trip-view}), %{
      conn: conn
    } do
      conn = get(conn, schedule_path(conn, :show, "Green", %{tab: "trip-view"}))
      assert conn.query_params == %{"tab" => "trip-view"}

      assert conn.status == 200

      assert conn.assigns.tab == "trip-view"
    end

    test ~s(renders alerts tab without redirecting when query params = %{tab => alerts}), %{
      conn: conn
    } do
      conn = get(conn, schedule_path(conn, :show, "Green", %{tab: "alerts"}))
      assert conn.query_params == %{"tab" => "alerts"}

      assert conn.status == 200

      assert conn.assigns.tab == "alerts"
    end

    test ~s(renders line tab without redirecting when query params = %{tab => trip-view}), %{
      conn: conn
    } do
      conn = get(conn, schedule_path(conn, :show, "Green", %{tab: "line"}))
      assert conn.query_params == %{"tab" => "line"}

      assert conn.status == 200

      assert conn.assigns.tab == "line"
    end
  end

  test "assigns the route as the Green Line", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green"))
    html_response(conn, 200)
    assert conn.assigns.route == @green_line
  end

  test "assigns the date and date_time", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green"))
    html_response(conn, 200)
    assert conn.assigns.date
    assert conn.assigns.date_time
  end

  test "assigns date select and calendar", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green", date_select: "true"))
    html_response(conn, 200)
    assert conn.assigns.date_select
    assert conn.assigns.calendar
  end

  test "assigns origin and destination", %{conn: conn} do
    conn =
      get(
        conn,
        schedule_path(conn, :show, "Green", origin: "place-pktrm", destination: "place-boyls")
      )

    assert conn.assigns.origin.id == "place-pktrm"
    assert conn.assigns.destination.id == "place-boyls"
  end

  test "sets a custom meta description", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green"))
    assert conn.assigns.meta_description
  end

  test "trip view :all_stops is a list of %Stop{} for all stops on all branches", %{conn: conn} do
    conn = get(conn, green_path(conn, :trip_view, %{direction_id: 0}))

    assert [%Stops.Stop{} | all_stops] = conn.assigns.all_stops

    all_stops = Enum.map(all_stops, & &1.id)
    assert "place-lake" in all_stops
    assert "place-clmnl" in all_stops
    assert "place-river" in all_stops
    assert "place-hsmnl" in all_stops
  end

  test "line tab :all_stops is a list of {bubble_info, %RouteStops{}} for all stops on all branches",
       %{conn: conn} do
    conn = get(conn, green_path(conn, :line, %{direction_id: 0}))
    assert [{bubble_types, stop} | all_stops] = conn.assigns.all_stops
    assert stop.id == "place-lech"

    assert bubble_types == [
             {"Green-B", :empty},
             {"Green-C", :empty},
             {"Green-D", :empty},
             {"Green-E", :terminus}
           ]

    all_stops = Enum.map(all_stops, fn {_, stop} -> stop.id end)
    assert "place-lake" in all_stops
    assert "place-clmnl" in all_stops
    assert "place-river" in all_stops
    assert "place-hsmnl" in all_stops
  end

  test "trip view assigns no stops and an error if the date is out of range", %{conn: conn} do
    conn = get(conn, green_path(conn, :trip_view, date: "2017-01-01"))
    assert conn.assigns.all_stops == []
    assert conn.assigns.schedule_error
  end

  describe "predictions" do
    test "assigns predictions and vehicle_predictions for all branches", %{conn: conn} do
      conn =
        conn
        |> assign(:date, ~D[2017-01-01])
        |> assign(:date_time, ~N[2017-01-01T12:00:00])
        |> assign(:origin, %Stops.Stop{id: "place-north"})
        |> assign(:destination, nil)
        |> assign(:direction_id, 0)
        |> assign(:route, @green_line)
        |> assign(:vehicle_locations, %{
          {"trip_1", "stop_1"} => %Vehicles.Vehicle{},
          {"trip_2", "stop_3"} => %Vehicles.Vehicle{}
        })
        |> predictions(
          predictions_fn: fn params ->
            case Enum.into(params, Map.new()) do
              # vehicle predictions
              %{trip: trip_ids, stop: stop_ids} ->
                Enum.map(
                  cartesian_product(trip_ids, stop_ids),
                  fn {trip_id, stop_id} ->
                    %Predictions.Prediction{
                      id: "vehicle_predictions",
                      trip: %Schedules.Trip{id: trip_id},
                      stop: %Stops.Stop{id: stop_id}
                    }
                  end
                )

              # predictions
              %{stop: _stop_id} ->
                [
                  %Predictions.Prediction{
                    id: "predictions",
                    trip: 1234,
                    route: %Routes.Route{id: params[:route]}
                  }
                ]
            end
          end
        )

      assert Enum.map(conn.assigns.predictions, & &1.route.id) == GreenLine.branch_ids()
      assert Enum.all?(conn.assigns.predictions, &(&1.id == "predictions"))

      vehicle_prediction_ids =
        conn.assigns.vehicle_predictions
        |> Enum.map(&{&1.trip.id, &1.stop.id})
        |> Enum.sort()

      assert vehicle_prediction_ids == [
               {"trip_1", "stop_1"},
               {"trip_1", "stop_3"},
               {"trip_2", "stop_1"},
               {"trip_2", "stop_3"}
             ]

      assert Enum.all?(conn.assigns.vehicle_predictions, &(&1.id == "vehicle_predictions"))
    end

    defp cartesian_product(xs, ys) do
      for x <- String.split(xs, ","),
          y <- String.split(ys, ",") do
        {x, y}
      end
    end
  end

  test "assigns vehicle locations for all branches", %{conn: conn} do
    conn =
      conn
      |> assign(:date, ~D[2017-01-01])
      |> assign(:date_time, ~N[2017-01-01T12:00:00])
      |> assign(:direction_id, 0)
      |> assign(:route, @green_line)
      |> vehicle_locations(
        schedule_for_trip_fn: fn _ -> [] end,
        location_fn: fn route_id, _ ->
          [
            %Vehicles.Vehicle{
              route_id: route_id,
              stop_id: "stop-#{route_id}",
              trip_id: "trip-#{route_id}"
            }
          ]
        end
      )

    assert conn.assigns.vehicle_locations
           |> Map.values()
           |> Enum.map(& &1.route_id)
           |> Kernel.==(GreenLine.branch_ids())
  end

  test "assigns excluded stops", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green", origin: "place-pktrm", direction_id: 0))

    assert conn.assigns.excluded_origin_stops ==
             ExcludedStops.excluded_origin_stops(0, "Green", conn.assigns.all_stops)

    assert conn.assigns.excluded_destination_stops ==
             ExcludedStops.excluded_destination_stops("Green", "place-pktrm")
  end

  test "trip view assigns journeys", %{conn: conn} do
    conn = get(conn, green_path(conn, :trip_view, origin: "place-pktrm"))

    assert conn.assigns.journeys.journeys
  end

  test "assigns breadcrumbs", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green"))

    assert conn.assigns.breadcrumbs
  end

  test "assigns stops_on_routes", %{conn: conn} do
    conn = get(conn, schedule_path(conn, :show, "Green", direction_id: 1))

    assert conn.assigns.stops_on_routes == GreenLine.stops_on_routes(1, conn.assigns.date)
  end

  test "if we select an origin where we only have non-trip predictions, we hide the destination selector",
       %{conn: conn} do
    conn =
      conn
      |> assign(:date_time, ~N[2017-01-01T12:00:00])
      |> assign(:date, ~D[2017-01-01])
      |> assign(:direction_id, 0)
      |> assign(:route, @green_line)
      |> assign(:origin, %Stops.Stop{id: "place-north"})
      |> hide_destination_selector([])

    assert conn.assigns.hide_destination_selector?
  end

  test "direction is reversed when origin and destination are not in order", %{conn: conn} do
    path =
      schedule_path(
        conn,
        :show,
        "Green",
        origin: "place-pktrm",
        destination: "place-bckhl",
        direction_id: 1
      )

    conn = get(conn, path)
    assert redirected_to(conn, 302) =~ "direction_id=0"
  end

  test "direction is not changed when origin and destination are in the correct order", %{
    conn: conn
  } do
    path =
      schedule_path(
        conn,
        :show,
        "Green",
        origin: "place-bckhl",
        destination: "place-pktrm",
        direction_id: 1
      )

    conn = get(conn, path)
    assert conn.assigns.direction_id == 1
  end

  describe "validate_journeys/2" do
    test "redirects away from a destination if we had origin predictions but not journeys", %{
      conn: conn
    } do
      conn =
        %{
          conn
          | request_path: "/",
            query_params: %{"origin" => "stop", "destination" => "destination"}
        }
        |> assign(:date_time, ~N[2017-01-01T12:00:00])
        |> assign(:date, ~D[2017-01-01])
        |> assign(:direction_id, 0)
        |> assign(:route, @green_line)
        |> assign(:origin, %Stops.Stop{id: "stop"})
        |> assign(:destination, %Stops.Stop{id: "destination"})
        |> assign(:predictions, [%Predictions.Prediction{stop: %Stops.Stop{id: "stop"}}])
        |> assign(:journeys, JourneyList.build_predictions_only([], [], "stop", "destination"))
        |> validate_journeys([])

      assert redirected_to(conn, 302) == "/?origin=stop"
    end

    test "keeps the destination if there are journeys", %{conn: conn} do
      predictions = [
        %Predictions.Prediction{stop: %Stops.Stop{id: "stop"}}
      ]

      conn =
        %{
          conn
          | request_path: "/",
            query_params: %{"origin" => "stop", "destination" => "destination"}
        }
        |> assign(:date_time, ~N[2017-01-01T12:00:00])
        |> assign(:date, ~D[2017-01-01])
        |> assign(:direction_id, 0)
        |> assign(:route, @green_line)
        |> assign(:origin, %Stops.Stop{id: "stop"})
        |> assign(:destination, %Stops.Stop{id: "destination"})
        |> assign(:predictions, predictions)
        |> assign(:journeys, JourneyList.build_predictions_only([], predictions, "stop", nil))
        |> validate_journeys([])

      refute conn.halted
    end

    test "keeps the destination if there are no predictions for the origin", %{conn: conn} do
      conn =
        %{
          conn
          | request_path: "/",
            query_params: %{"origin" => "stop", "destination" => "destination"}
        }
        |> assign(:date_time, ~N[2017-01-01T12:00:00])
        |> assign(:date, ~D[2017-01-01])
        |> assign(:direction_id, 0)
        |> assign(:route, @green_line)
        |> assign(:origin, %Stops.Stop{id: "stop"})
        |> assign(:destination, %Stops.Stop{id: "destination"})
        |> assign(:predictions, [%Predictions.Prediction{stop: %Stops.Stop{id: "destination"}}])
        |> assign(:journeys, JourneyList.build_predictions_only([], [], "stop", "destination"))
        |> validate_journeys([])

      refute conn.halted
    end

    test "does nothing if there's no destination", %{conn: conn} do
      conn =
        %{conn | request_path: "/", query_params: %{"origin" => "stop"}}
        |> assign(:date_time, ~N[2017-01-01T12:00:00])
        |> assign(:date, ~D[2017-01-01])
        |> assign(:direction_id, 0)
        |> assign(:route, @green_line)
        |> assign(:origin, %Stops.Stop{id: "stop"})
        |> assign(:destination, nil)
        |> assign(:predictions, [%Predictions.Prediction{stop: %Stops.Stop{id: "stop"}}])
        |> assign(:journeys, JourneyList.build_predictions_only([], [], "stop", "destination"))
        |> validate_journeys([])

      refute conn.halted
    end
  end
end
