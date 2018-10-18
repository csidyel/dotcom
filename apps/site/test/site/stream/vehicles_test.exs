defmodule Site.Stream.VehiclesTest do
  use SiteWeb.ChannelCase, async: true
  alias Vehicles.Vehicle

  def fetch([]) do
    [
      %Vehicle{route_id: "Red", direction_id: 0},
      %Vehicle{route_id: "CR-Lowell", direction_id: 1},
      %Vehicle{route_id: "Blue", direction_id: nil},
      %Vehicle{route_id: "Green-B", direction_id: 1},
      %Vehicle{route_id: "Green-C", direction_id: 1}
    ]
  end

  test "start_link/1" do
    assert {:ok, _} = Site.Stream.Vehicles.start_link(name: __MODULE__)
  end

  test "broadcasts vehicles by route and direction id" do
    SiteWeb.Endpoint.subscribe("vehicles:Red:0")
    SiteWeb.Endpoint.subscribe("vehicles:CR-Lowell:1")
    SiteWeb.Endpoint.subscribe("vehicles:Blue:0")
    SiteWeb.Endpoint.subscribe("vehicles:Blue:1")

    assert {:ok, _} = GenServer.start_link(Site.Stream.Vehicles, [repo: __MODULE__])

    assert_broadcast "data", %{data: [
      %Vehicle{route_id: "Red", direction_id: 0}
    ]}

    assert_broadcast "data", %{data: [
      %Vehicle{route_id: "CR-Lowell", direction_id: 1}
    ]}

    refute_broadcast "data", %{data: [
      %Vehicle{route_id: "Blue", direction_id: nil}
    ]}
  end

  test "sends a generic Green broadcast" do
    SiteWeb.Endpoint.subscribe("vehicles:Green:1")
    assert {:ok, _} = GenServer.start_link(Site.Stream.Vehicles, [repo: __MODULE__])

    assert_broadcast "data", %{data: [
      %Vehicle{route_id: "Green-B", direction_id: 1},
      %Vehicle{route_id: "Green-C", direction_id: 1}
    ]}
  end
end
