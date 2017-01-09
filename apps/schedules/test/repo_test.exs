defmodule Schedules.RepoTest do
  use ExUnit.Case, async: true
  use Timex
  import Schedules.Repo
  alias Schedules.{Schedule, Stop}

  describe "all/1" do
    test "can take a route/direction/sequence/date" do
      response = all(
        route: "CR-Lowell",
        date: Util.service_date,
        direction_id: 1,
        stop_sequence: "first")
      assert response != []
      assert %Schedule{} = List.first(response)
    end

    test "returns the parent station as the stop" do
      response = all(
        route: "Red",
        date: Util.service_date,
        direction_id: 0,
        stop_sequence: "first")
      assert response != []
      assert %Stop{id: "place-alfcl", name: "Alewife"} == List.first(response).stop
    end

    test "inbound Lowell with stop_sequence: first includes Anderson/ Woburn trip" do
      next_weekday = "America/New_York"
      |> Timex.now()
      |> Timex.end_of_week(:mon)
      |> Timex.shift(days: 3)
      |> Timex.format!("{ISOdate}")

      response = all(
        route: "CR-Lowell",
        date: next_weekday,
        direction_id: 1,
        stop_sequence: "first")

      assert Enum.any?(response, &match?(%Schedule{stop: %Stop{id: "Lowell"}}, &1))
      assert Enum.any?(response, &match?(%Schedule{stop: %Stop{id: "Anderson/ Woburn"}}, &1))
    end
  end

  describe "stops/2" do
    test "returns a list of stops in order of their stop_sequence" do
      response = stops(
        "CR-Lowell",
        date: Util.service_date,
        direction_id: 1)

      assert response != []
      assert List.first(response) == %Stop{id: "Lowell", name: "Lowell"}
      assert List.last(response) == %Stop{id: "place-north", name: "North Station"}
      assert response == Enum.uniq(response)
    end

    test "uses the parent station name" do
      next_weekday = "America/New_York"
      |> Timex.now()
      |> Timex.to_date
      |> Timex.end_of_week(:mon)
      |> Timex.shift(days: 3)

      response = stops(
        "Green-B",
        date: next_weekday,
        direction_id: 0)

      assert response != []
      assert List.first(response) == %Stop{id: "place-pktrm", name: "Park Street"}
    end

    test "does not include a parent station multiple times" do
      # stops multiple times at Sullivan
      response = stops(
        "86",
        date: Util.service_date,
        direction_id: 1)

      assert response != []
      refute (response |> Enum.at(1)).id == "place-sull"
    end
  end

  test ".schedule_for_trip returns stops in order of their stop_sequence for a given trip" do
    # find a Lowell trip ID
    trip_id = "Lowell"
    |> schedule_for_stop(direction_id: 1)
    |> List.first
    |> Map.get(:trip)
    |> Map.get(:id)
    response = schedule_for_trip(trip_id)
    assert response |> Enum.all?(fn schedule -> schedule.trip.id == trip_id end)
    refute response == []
    assert List.first(response).stop.id == "Lowell"
    assert List.last(response).stop.id == "place-north"
  end

  describe "trip/1" do
    test "returns nil for an invalid trip ID" do
      assert trip("invalid ID") == nil
    end

    test "returns a %Schedule.Trip{} for a given ID" do
      schedules = all(route: "1", date: Util.service_date |> Timex.shift(days: 1), stop_sequence: :first, direction_id: 0)
      scheduled_trip = List.first(schedules).trip
      assert scheduled_trip == trip(scheduled_trip.id)
    end
  end

  describe "origin_destination/3" do
    test "returns pairs of Schedule items" do
      today = Util.service_date |> Timex.format!("{ISOdate}")
      response = origin_destination("Anderson/ Woburn", "North Station",
        date: today, direction_id: 1)
      [{origin, dest}|_] = response

      assert origin.stop.id == "Anderson/ Woburn"
      assert dest.stop.id == "place-north"
      assert origin.trip.id == dest.trip.id
      assert origin.time < dest.time
    end

    test "does not require a direction id" do
      today = Util.service_date |> Timex.format!("{ISOdate}")
      no_direction_id = origin_destination("Anderson/ Woburn", "North Station",
        date: today)
      direction_id = origin_destination("Anderson/ Woburn", "North Station",
        date: today, direction_id: 1)

      assert no_direction_id == direction_id
    end

    test "does not return duplicate trips if a stop hits multiple stops with the same parent" do
      next_tuesday = "America/New_York"
      |> Timex.now()
      |> Timex.end_of_week(:wed)
      |> Timex.format!("{ISOdate}")
      # stops multiple times at ruggles
      response = origin_destination("place-rugg", "1237", route: "43", date: next_tuesday)
      trips = Enum.map(response, fn {origin, _} -> origin.trip.id end)
      assert trips == Enum.uniq(trips)
    end
  end
end
