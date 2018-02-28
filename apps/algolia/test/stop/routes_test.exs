defmodule Algolia.Stop.RoutesTest do
  use ExUnit.Case, async: true

  describe "&for_stop/2" do
    test "builds a route list for a stop with multiple modes" do
      repo_fn = fn "place-test" ->
        [
          %Routes.Route{id: "Green-C", name: "Green Line C", type: 0},
          %Routes.Route{id: "Red", name: "Red Line", type: 1},
          %Routes.Route{id: "CR-Fitchburg", name: "Fitchburg Line", type: 2},
          %Routes.Route{id: "1000", name: "1000", type: 3},
          %Routes.Route{id: "Boat-F1", name: "Ferry", type: 4}
        ]
      end
      assert [light_rail, heavy_rail, commuter_rail, bus, ferry] = Algolia.Stop.Routes.for_stop("place-test", repo_fn)
      assert light_rail == %Algolia.Stop.Route{display_name: "Green Line", icon: :green_line}
      assert heavy_rail  == %Algolia.Stop.Route{display_name: "Red Line", icon: :red_line}
      assert commuter_rail == %Algolia.Stop.Route{display_name: "Commuter Rail", icon: :commuter_rail}
      assert bus == %Algolia.Stop.Route{display_name: "Bus: 1000", icon: :bus}
      assert ferry == %Algolia.Stop.Route{display_name: "Ferry", icon: :ferry}
    end
  end
end
