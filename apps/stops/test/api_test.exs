defmodule Stops.ApiTest do
  use ExUnit.Case

  alias Stops.Stop

  test "all returns more than 25 items" do
    all = Stops.Api.all
    assert length(all) > 25
    assert all == Enum.uniq(all)
  end

  test "by_gtfs_id uses the gtfs parameter" do
    stop = Stops.Api.by_gtfs_id("Anderson/ Woburn")

    assert stop.id == "Anderson/ Woburn"
    assert stop.name == "Anderson/Woburn"
    assert stop.station?
    assert stop.accessibility != []
    assert stop.parking_lots != []
    for parking_lot <- stop.parking_lots do
      assert %Stop.ParkingLot{} = parking_lot
      assert parking_lot.spots != nil
      manager = parking_lot.manager
      assert manager.name == "Massport"
    end
  end

  test "by_gtfs_id can use the GTFS accessibility data" do
    stop = Stops.Api.by_gtfs_id("Yawkey")
    assert ["accessible" | _] = stop.accessibility
  end

  test "by_gtfs_id returns nil if stop is not found" do
    assert Stops.Api.by_gtfs_id("-1") == nil
  end

  test "by_gtfs_id returns a stop even if the stop is not a station" do
    stop = Stops.Api.by_gtfs_id("411")

    assert stop.id == "411"
    assert stop.name == "Warren St @ Brunswick St"
    assert stop.latitude != nil
    assert stop.longitude != nil
    refute stop.station?
  end

  test "by_route returns an error tuple if the V3 API returns an error" do
    bypass = Bypass.open
    v3_url = Application.get_env(:v3_api, :base_url)
    on_exit fn ->
      Application.put_env(:v3_api, :base_url, v3_url)
    end

    Application.put_env(:v3_api, :base_url, "http://localhost:#{bypass.port}")

    Bypass.expect bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end

    assert {:error, _} = Stops.Api.by_route({"1", 0, []})
  end
end
