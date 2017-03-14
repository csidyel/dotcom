defmodule MapHelpersTest do
  use Site.ConnCase, async: true
  import MapHelpers

  describe "map_pdf_url/1" do
    test "returns the map link for subway" do
      assert map_pdf_url(:subway)  == "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
    end

    test "returns the map link for ferry" do
      assert map_pdf_url(:ferry)  == "https://s3.amazonaws.com/mbta-dotcom/Water_Ferries_2016.pdf"
    end

    test "returns the bus map for bus" do
      assert map_pdf_url(:bus)  == "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
    end

    test "returns the map link for commuter rail" do
      assert map_pdf_url(:commuter_rail)  == "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
    end

    test "works when given a route type number instead of an atom" do
      assert map_pdf_url(1)  == "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Rapid%20Transit%20w%20Key%20Bus.pdf"
      assert map_pdf_url(4)  == "https://s3.amazonaws.com/mbta-dotcom/Water_Ferries_2016.pdf"
    end

    test "gives nil when the number does not correspond to a route type" do
      assert map_pdf_url(9)  == nil
    end
  end
end
