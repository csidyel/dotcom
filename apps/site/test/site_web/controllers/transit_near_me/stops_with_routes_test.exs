defmodule SiteWeb.TransitNearMeController.StopsWithRoutesTest do
  use ExUnit.Case, async: true

  alias GoogleMaps.Geocode.Address
  alias Routes.Route
  alias Schedules.Schedule
  alias Site.TransitNearMe
  alias SiteWeb.TransitNearMeController.StopsWithRoutes
  alias Stops.Stop

  @mattapan %Route{id: "Mattapan", name: "Mattapan Trolley", type: 0}
  @green_branch %Route{id: "Green-B", name: "Green Line B", type: 0}
  @subway %Route{id: "Red", name: "Red Line", type: 1}
  @cr %Route{id: "CR-Commuterrail", name: "Commuter Rail", type: 2}
  @bus %Route{id: "111", name: "Bus", type: 3}
  @ferry %Route{id: "Boat-Ferry", name: "Ferry", type: 4}

  @stop %Stop{
    id: "stop-id",
    name: "Stop Name",
    latitude: 42.352,
    longitude: -71.067
  }

  describe "from_routes_and_stops/1" do
    setup do
      data = %TransitNearMe{
        schedules: %{
          "stop-id" => [
            %Schedule{route: @mattapan, stop: @stop},
            %Schedule{route: @green_branch, stop: @stop},
            %Schedule{route: @subway, stop: @stop},
            %Schedule{route: @cr, stop: @stop},
            %Schedule{route: @bus, stop: @stop},
            %Schedule{route: @ferry, stop: @stop}
          ]
        },
        distances: %{
          "stop-id" => 0.04083664794103045
        },
        stops: [@stop]
      }

      %{data: data}
    end

    test "builds a list of stops and the routes that stop at each one", %{
      data: data
    } do
      stops = StopsWithRoutes.from_routes_and_stops(data)

      assert [
               %{
                 stop: stop,
                 distance: distance,
                 routes: routes
               }
             ] = stops

      assert %Stop{} = stop

      assert distance == 0.04083664794103045

      expected_routes = [
        red_line: [@subway],
        mattapan_trolley: [@mattapan],
        green_line: [Route.to_naive(@green_branch)],
        bus: [@bus],
        commuter_rail: [@cr],
        ferry: [@ferry]
      ]

      assert routes == expected_routes
    end
  end

  describe "stops_with_routes/2" do
    test "returns an encodable map with formatted data" do
      location = %Address{
        latitude: 42.351,
        longitude: -71.066,
        formatted: "10 Park Plaza, Boston, MA, 02116"
      }

      stops = %TransitNearMe{
        schedules: %{
          "stop-id" => [
            %Schedule{route: @mattapan, stop: @stop},
            %Schedule{route: @green_branch, stop: @stop},
            %Schedule{route: @subway, stop: @stop},
            %Schedule{route: @cr, stop: @stop},
            %Schedule{route: @bus, stop: @stop},
            %Schedule{route: @ferry, stop: @stop}
          ]
        },
        distances: %{
          "stop-id" => 0.04083664794103045
        },
        stops: [@stop]
      }

      stops_map = StopsWithRoutes.stops_with_routes(stops, location)

      %{stop: stop, routes: routes} = List.first(stops_map)
      route = routes |> List.first() |> Map.get(:routes) |> List.first()

      assert [:href | %Route{} |> Map.from_struct() |> Map.keys()] |> Enum.sort() ==
               route |> Map.keys() |> Enum.sort()

      assert [:distance, :href | %Stop{} |> Map.from_struct() |> Map.keys()]
             |> Enum.sort() == stop |> Map.keys() |> Enum.sort()

      assert stop.distance == "500 ft"
      assert {:ok, _} = Poison.encode(stops_map)
    end
  end
end
