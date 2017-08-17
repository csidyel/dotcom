defmodule Site.ScheduleV2Controller.TripInfoTest do
  use Site.ConnCase, async: true
  import Site.ScheduleV2Controller.TripInfo
  alias Schedules.{Schedule, Trip}
  alias Stops.Stop
  alias Predictions.Prediction

  @time ~N[2017-02-10T20:00:00]
  @date Timex.to_date(@time)

  @schedules [
    %Schedule{
      trip: %Trip{id: "past_trip"},
      stop: %Stop{},
      time: Timex.shift(@time, hours: -1)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Stop{},
      time: Timex.shift(@time, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "far_future_trip"},
      stop: %Stop{},
      time: Timex.shift(@time, hours: 1)
    }
  ]
  @trip_schedules [
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Stop{id: "first"},
      time: Timex.shift(@time, minutes: 5)
    },
    %Schedule{
      trip: %Trip{id: "32893585"},
      stop: %Stop{id: "last"},
      time: Timex.shift(@time, minutes: 4)
    }
  ]

  @predictions [
    %Prediction{
      trip: %Trip{id: "32893585"},
      stop: %Stop{id: "first"}
    },
    %Prediction{
      trip: %Trip{id: "32893585"},
      stop: %Stop{id: "last"}
    }
  ]

  setup %{conn: conn} do
    conn = conn
    |> assign(:date_time, @time)
    |> assign(:date, @date)
    {:ok, %{conn: conn}}
  end

  defp prediction_fn([trip: trip_id]) do
    Enum.map(@predictions, &(%Prediction{&1 | trip: %Trip{id: trip_id}}))
  end

  defp trip_fn("32893585", [date: @date]) do
    @trip_schedules
  end
  defp trip_fn("long_trip", [date: @date]) do
    # add some extra schedule data so that we can collapse this trip
    # make sure all schedules have "long_trip" as ID, since that's this trip_fn match
    @trip_schedules
    |> Enum.concat([
      %Schedule{
        stop: %Stop{id: "after_first"},
        time: Timex.shift(List.last(@schedules).time, minutes: -4)
      },
      %Schedule{
        stop: %Stop{id: "1"},
        time: Timex.shift(List.last(@schedules).time, minutes: -3)
      },
      %Schedule{
        stop: %Stop{id: "2"},
        time: Timex.shift(List.last(@schedules).time, minutes: -2)
      },
      %Schedule{
        stop: %Stop{id: "3"},
        time: Timex.shift(List.last(@schedules).time, minutes: -1)
      },
      %Schedule{
        stop: %Stop{id: "new_last"},
        time: List.last(@schedules).time
      }
    ])
    |> Enum.map(& %Schedule{&1 | trip: %Trip{id: "long_trip"}})
  end
  defp trip_fn("not_in_schedule", [date: @date]) do
    []
  end
  defp trip_fn("out_of_service", _) do
    {:error, [%JsonApi.Error{code: "no_service"}]}
  end

  defp vehicle_fn("32893585") do
    %Vehicles.Vehicle{}
  end
  defp vehicle_fn(_) do
    nil
  end

  defp conn_builder(conn, schedules, params \\ []) do
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)
    query_params = Map.new(params, fn {key, val} -> {Atom.to_string(key), val} end)
    params = put_in query_params["route"], "1"

    %{conn |
      request_path: schedule_path(conn, :show, "1"),
      query_params: query_params,
      params: params}
    |> assign_journeys_from_schedules(schedules)
    |> call(init)
  end

  defp assign_journeys_from_schedules(conn, schedules) do
    journeys = Enum.map(schedules, & %Journey{departure: %PredictedSchedule{schedule: &1}})
    assign(conn, :journeys, %JourneyList{journeys: journeys})
  end

  defp assign_journeys_from_schedules_and_predictions(conn, schedules, predictions) do
    journeys = schedules
    |> Enum.zip(predictions)
    |> Enum.map(fn {schedule, prediction} ->
      %Journey{departure: %PredictedSchedule{schedule: schedule, prediction: prediction}}
    end)

    assign(conn, :journeys, %JourneyList{journeys: journeys})
  end

  test "does not assign a trip when schedules is empty", %{conn: conn} do
    conn = conn_builder(conn, [])
    assert conn.assigns.trip_info == nil
  end

  test "assigns trip_info when origin/destination are selected", %{conn: conn} do
    expected_stops = ["after_first", "1", "2", "3", "new_last"]
    conn = conn_builder(conn, [], trip: "long_trip", origin: "after_first", destination: "new_last")
    actual_stops = conn.assigns.trip_info.times
    |> Enum.map(& &1.schedule.stop.id)
    assert actual_stops == expected_stops
  end

  test "assigns the total number of stops", %{conn: conn} do
    conn = conn_builder(conn, [], trip: "long_trip")
    assert conn.assigns[:trip_info].stop_count == 7

    conn = conn_builder(conn, [], trip: "32893585")
    assert conn.assigns.trip_info.stop_count == 2
  end

  test "does not assign a trip if there are no more trips left in the day", %{conn: conn} do
    conn = conn_builder(conn, [List.first(@schedules)])
    assert conn.assigns.trip_info == nil
  end

  test "redirects if we can't generate a trip info", %{conn: conn} do
    conn = conn_builder(
      conn, @schedules,
      trip: "not_in_schedule",
      origin: "fake",
      destination: "fake",
      param: "param")
    expected_path = schedule_path(conn, :show, "1", destination: "fake", origin: "fake", param: "param")
    assert conn.halted
    assert redirected_to(conn) == expected_path
  end

  test "does not redirect if we didn't have a trip already", %{conn: conn} do
    conn = conn_builder(
      conn, @schedules,
      origin: "fake",
      destination: "fake")
    refute conn.halted
    refute conn.assigns.trip_info
  end

  test "Trip predictions are not fetched if date is not service day", %{conn: conn} do
    future_date = Timex.shift(@date, days: 2)
    future_trip_fn = fn "long_trip" = trip_id, [date: ^future_date] -> trip_fn(trip_id, date: @date) end
    init = init(trip_fn: future_trip_fn, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)
    conn = %{conn |
      request_path: schedule_path(conn, :show, "1"),
      query_params: %{"trip" =>  "long_trip"}}
    |> assign(:schedules, [])
    |> assign(:date, future_date)
    |> call(init)

    for %PredictedSchedule{schedule: _schedule, prediction: prediction} <- conn.assigns.trip_info.times do
      refute prediction
    end
  end

  test "Trip predictions are fetched if date is service day", %{conn: conn} do
    conn = conn
    |> conn_builder([], trip: "long_trip")
    predicted_schedules = conn.assigns.trip_info.times
    assert Enum.find(predicted_schedules, &match?(%PredictedSchedule{prediction: %Prediction{}}, &1))
  end

  test "does not assign trips for the subway if the date is in the future", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 25),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 26),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 27),
        route: %Routes.Route{type: 1}
      }
    ]
    day = Timex.shift(@date, days: 1)
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "Red"),
      query_params: nil
    }
    |> assign(:schedules, schedules)
    |> assign(:date, day)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert conn.assigns.trip_info == nil
  end

  test "Default Trip id is taken from journeys if one is not provided", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 10),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 15),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 20),
        route: %Routes.Route{type: 1}
      }
    ]
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "66"),
      query_params: nil
    }
    |> assign_journeys_from_schedules(schedules)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    for time <- conn.assigns.trip_info.times do
      assert PredictedSchedule.trip(time).id == "32893585"
    end
  end

  test "Default Trip id is an upcoming trip", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "long_trip"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: -10),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 15),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "not_in_schedule"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 20),
        route: %Routes.Route{type: 1}
      }
    ]
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1, prediction_fn: &prediction_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "66"),
      query_params: nil
    }
    |> assign_journeys_from_schedules(schedules)
    |> assign(:route, %Routes.Route{type: 1})
    |> assign(:date, ~D[2017-02-10])
    |> assign(:datetime, @time)
    |> call(init)

    assert TripInfo.is_current_trip?(conn.assigns.trip_info, "32893585")
  end

  test "Default Trip id is an upcoming trip, defers to prediction over schedule", %{conn: conn} do
    # the long_trip is scheduled for 10 minutes ago
    schedules = [
      %Schedule{
        trip: %Trip{id: "long_trip"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: -10),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 15),
        route: %Routes.Route{type: 1}
      }
    ]

    # however, with delays the long_trip is predicted to arrive in one minute
    predictions = [
      %Prediction{
        trip: %Trip{id: "long_trip"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 1),
        route: %Routes.Route{type: 1}
      },
      %Prediction{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 20),
        route: %Routes.Route{type: 1}
      }
    ]

    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1, prediction_fn: fn _ -> [] end)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "66"),
      query_params: nil
    }
    |> assign_journeys_from_schedules_and_predictions(schedules, predictions)
    |> assign(:route, %Routes.Route{type: 1})
    |> assign(:date, ~D[2017-02-10])
    |> assign(:datetime, @time)
    |> call(init)

    assert TripInfo.is_current_trip?(conn.assigns.trip_info, "long_trip")
  end

  test "does assign trips for the subway if the date is today", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 25),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, minutes: 26),
        route: %Routes.Route{type: 1}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 27),
        route: %Routes.Route{type: 1}
      }
    ]
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "Red"),
      query_params: nil
    }
    |> assign_journeys_from_schedules(schedules)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert conn.assigns.trip_info != nil
  end

  test "does assign trips for the bus if the date is in the future", %{conn: conn} do
    schedules = [
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 25),
        route: %Routes.Route{type: 3}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 26),
        route: %Routes.Route{type: 3}
      },
      %Schedule{
        trip: %Trip{id: "32893585"},
        stop: %Stop{},
        time: Timex.shift(@time, hours: 27),
        route: %Routes.Route{type: 3}
      }
    ]
    day = Timex.shift(@date, days: 1)
    future_trip_fn = fn "32893585" = trip_id, [date: ^day] -> trip_fn(trip_id, date: @date) end
    init = init(trip_fn: future_trip_fn, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "1"),
      query_params: nil
    }
    |> assign_journeys_from_schedules(schedules)
    |> assign(:date, day)
    |> assign(:route, %Routes.Route{type: 3})
    |> call(init)

    assert conn.assigns.trip_info != nil
  end

  test "does not assign trips if the prediction doesn't have a time", %{conn: conn} do
    prediction = %Prediction{trip: %Trip{id: "trip"}, stop: %Stop{id: "origin"}, route: %Routes.Route{}}
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "1"),
      query_params: nil
    }
    |> assign(:journeys, JourneyList.build_predictions_only([], [prediction], "origin", nil))
    |> assign(:date, ~D[2017-01-01])
    |> assign(:date_time, ~N[2017-01-01T12:00:00])
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert conn.assigns.trip_info == nil
  end

  test "does not assign trips if the prediction doesn't have a trip", %{conn: conn} do
    prediction = %Prediction{time: ~N[2017-01-01T13:00:00], stop: %Stop{id: "origin"}, route: %Routes.Route{}}
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "1"),
      query_params: nil
    }
    |> assign(:journeys, JourneyList.build_predictions_only([], [prediction], "origin", nil))
    |> assign(:date, ~D[2017-01-01])
    |> assign(:date_time, ~N[2017-01-01T12:00:00])
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert conn.assigns.trip_info == nil
  end

  test "removes the trip from the query string if the API returns an error", %{conn: conn} do
    init = init(trip_fn: &trip_fn/2, vehicle_fn: &vehicle_fn/1)

    conn = %{conn |
      request_path: schedule_path(conn, :show, "Red"),
      query_params: %{"trip" => "out_of_service"}
    }
    |> assign(:schedules, [])
    |> assign(:date, @date)
    |> assign(:route, %Routes.Route{type: 1})
    |> call(init)

    assert redirected_to(conn) == schedule_path(conn, :show, "Red")
  end

  describe "show_trips?/4" do
    test "it is false when looking at a future date for subway" do
      next_day = Timex.shift(@time, days: 1)
      assert Site.ScheduleV2Controller.TripInfo.show_trips?(next_day, @time, 1, "1") == false
    end

    test "is true when looking at the subway today" do
      assert Site.ScheduleV2Controller.TripInfo.show_trips?(@time, @time, 1, "1") == true
    end

    test "has the same behavior for light rail as for subway" do
      next_day = Timex.shift(@time, days: 1)
      assert Site.ScheduleV2Controller.TripInfo.show_trips?(@time, @time, 0, "1") == true
      assert Site.ScheduleV2Controller.TripInfo.show_trips?(next_day, @time, 0, "1") == false
    end

    test "is true when looking at any non-subway route" do
      next_day = Timex.shift(@time, days: 1)
      assert Site.ScheduleV2Controller.TripInfo.show_trips?(next_day, @time, 3, "1") == true
    end
  end
end
