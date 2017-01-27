defmodule Site.ScheduleV2Controller.StopTimesTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.StopTimes
  import Plug.Conn, only: [assign: 3, fetch_query_params: 1]

  alias Schedules.{Schedule, Trip, Stop}

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    defp setup_conn(params, schedules, predictions, now) do
      %{build_conn() | params: params}
      |> assign(:schedules, schedules)
      |> assign(:predictions, predictions)
      |> assign(:date_time, now)
      |> fetch_query_params
      |> call([])
    end

    test "assigns stop_times" do
      conn = setup_conn(%{}, [], [], Util.now)

      assert conn.assigns.stop_times == %StopTimeList{times: [], showing_all?: false}
    end

    test "filters out schedules in the past by default, leaving the last entry before now" do
      now = Util.now
      stop = %Stop{id: "stop"}
      schedules = for hour <- [-3, -2, -1, 1, 2, 3] do
        %Schedule{
          time: Timex.shift(now, hours: hour),
          trip: %Trip{id: "trip-#{hour}"},
          stop: stop
        }
      end
      conn = setup_conn(%{"origin" => stop.id}, schedules, [], now)

      assert conn.assigns.stop_times == StopTimeList.build(Enum.drop(schedules, 2), [], stop.id, nil, false)
    end

    test "if show_all_trips is true, doesn't filter schedules" do
      now = Util.now
      stop = %Stop{id: "stop"}
      schedules = for hour <- [-3, -2, -1, 1, 2, 3] do
        %Schedule{
          time: Timex.shift(now, hours: hour),
          trip: %Trip{id: "trip-#{hour}"},
          stop: stop
        }
      end
      conn = setup_conn(
        %{"origin" => stop.id, "show_all_trips" => "true"},
        schedules,
        [],
        now
      )

      assert conn.assigns.stop_times == StopTimeList.build(schedules, [], stop.id, nil, true)
    end

    test "assigns stop_times for subway", %{conn: conn} do
      conn = conn
      |> assign(:route, %Routes.Route{type: 1})
      |> assign(:schedules, [])
      |> assign(:predictions, [])
      |> fetch_query_params
      |> call([])

      assert conn.assigns.stop_times != nil
    end

    test "filters out predictions belonging to a trip that doesn't go to the destination" do
      now = Util.now
      origin = %Stop{id: "origin"}
      destination = %Stop{id: "destination"}
      elsewhere = %Stop{id: "elsewhere"}
      # Schedules that go to the destination
      destination_schedules = for hour <- [1, 2, 3] do
        {
          %Schedule{
            time: Timex.shift(now, hours: hour),
            trip: %Trip{id: "trip-#{hour}"},
            stop: origin
          },
          %Schedule{
            time: Timex.shift(now, hours: hour + 1),
            trip: %Trip{id: "trip-#{hour}"},
            stop: destination
          }
        }
      end
      # Schedules that don't go through the destination
      extra_schedules = for hour <- [4, 5, 6] do
        {
          %Schedule{
            time: Timex.shift(now, hours: hour),
            trip: %Trip{id: "trip-#{hour}"},
            stop: origin
          },
          %Schedule{
            time: Timex.shift(now, hours: hour + 1),
            trip: %Trip{id: "trip-#{hour}"},
            stop: elsewhere
          }
        }
      end
      all_schedules = destination_schedules ++ extra_schedules

      # Predictions at the destination
      destination_predictions = for hour <- [1, 2, 3] do
        %Predictions.Prediction{trip: %Trip{id: "trip-#{hour}"}, stop_id: destination.id}
      end
      # Predictions that should be filtered out
      extra_predictions = for hour <- [4, 5, 6] do
        %Predictions.Prediction{trip: %Trip{id: "trip-#{hour}"}, stop_id: elsewhere.id}
      end

      conn = setup_conn(
        %{"origin" => origin.id, "destination" => destination.id},
        all_schedules,
        destination_predictions ++ extra_predictions,
        now
      )

      assert conn.assigns.stop_times == StopTimeList.build(
        all_schedules,
        destination_predictions,
        origin.id,
        destination.id,
        false
      )
    end
  end
end
