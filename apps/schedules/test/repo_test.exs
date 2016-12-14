defmodule Schedules.RepoTest do
  use ExUnit.Case, async: true
  use Timex

  test ".all can take a route/direction/sequence/date" do
    response = Schedules.Repo.all(
      route: "CR-Lowell",
      date: Timex.today,
      direction_id: 1,
      stop_sequence: "first")
    assert response != []
    assert %Schedules.Schedule{} = List.first(response)
  end

  test ".all returns the parent station as the stop" do
    response = Schedules.Repo.all(
      route: "Red",
      date: Timex.today,
      direction_id: 0,
      stop_sequence: "first")
    assert response != []
    assert %Schedules.Stop{id: "place-alfcl", name: "Alewife"} == List.first(response).stop
  end

  test ".stops returns a list of stops in order of their stop_sequence" do
    response = Schedules.Repo.stops(
      "CR-Lowell",
      date: Timex.today,
      direction_id: 1)

    assert response != []
    assert List.first(response) == %Schedules.Stop{id: "Lowell", name: "Lowell"}
    assert List.last(response) == %Schedules.Stop{id: "place-north", name: "North Station"}
    assert response == Enum.uniq(response)
  end

  test ".stops uses the parent station name" do
    next_weekday = "America/New_York"
    |> Timex.now()
    |> Timex.to_date
    |> Timex.end_of_week(:mon)
    |> Timex.shift(days: 3)

    response = Schedules.Repo.stops(
      "Green-B",
      date: next_weekday,
      direction_id: 0)

    assert response != []
    assert List.first(response) == %Schedules.Stop{id: "place-pktrm", name: "Park Street"}
  end

  test ".stops does not include a parent station multiple times" do
    # stops multiple times at Sullivan
    response = Schedules.Repo.stops(
      "86",
      date: Timex.today,
      direction_id: 1)

    assert response != []
    refute (response |> Enum.at(1)).id == "place-sull"
  end

  test ".schedule_for_trip returns stops in order of their stop_sequence for a given trip" do
    # find a Lowell trip ID
    trip_id = "Lowell"
    |> Schedules.Repo.schedule_for_stop(direction_id: 1)
    |> List.first
    |> Map.get(:trip)
    |> Map.get(:id)
    response = Schedules.Repo.schedule_for_trip(trip_id)
    assert response |> Enum.all?(fn schedule -> schedule.trip.id == trip_id end)
    refute response == []
    assert List.first(response).stop.id == "Lowell"
    assert List.last(response).stop.id == "place-north"
  end

  describe "origin_destination/3" do
    test "returns pairs of Schedule items" do
      today = Timex.today |> Timex.format!("{ISOdate}")
      response = Schedules.Repo.origin_destination("Anderson/ Woburn", "North Station",
        date: today, direction_id: 1)
      [{origin, dest}|_] = response

      assert origin.stop.id == "Anderson/ Woburn"
      assert dest.stop.id == "place-north"
      assert origin.trip.id == dest.trip.id
      assert origin.time < dest.time
    end

    test "does not require a direction id" do
      today = Timex.today |> Timex.format!("{ISOdate}")
      no_direction_id = Schedules.Repo.origin_destination("Anderson/ Woburn", "North Station",
        date: today)
      direction_id = Schedules.Repo.origin_destination("Anderson/ Woburn", "North Station",
        date: today, direction_id: 1)

      assert no_direction_id == direction_id
    end

    test "does not return duplicate trips if a stop hits multiple stops with the same parent" do
      next_tuesday = "America/New_York"
      |> Timex.now()
      |> Timex.end_of_week(:wed)
      |> Timex.format!("{ISOdate}")
      # stops multiple times at ruggles
      response = Schedules.Repo.origin_destination("place-rugg", "1237", route: "43", date: next_tuesday)
      trips = Enum.map(response, fn {origin, _} -> origin.trip.id end)
      assert trips == Enum.uniq(trips)
    end
  end
end
