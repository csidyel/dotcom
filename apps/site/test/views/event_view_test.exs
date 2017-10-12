defmodule Site.EventViewTest do
  use Site.ViewCase, async: true
  import Site.EventView

  describe "index.html" do
    test "includes links to the previous and next month", %{conn: conn} do
      html =
        Site.EventView
        |> render_to_string(
          "index.html",
          conn: conn,
          events: [],
          month: "2017-01-15"
        )

      assert html =~ "href=\"/events?month=2016-12-01\""
      assert html =~ "href=\"/events?month=2017-02-01\""
    end
  end

  describe "show.html" do
    test "the notes section is not rendered when the event notes are empty", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:notes, nil)

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      refute html =~ "Notes"
    end

    test "the agenda section is not renderd when the event agenda is empty", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:agenda, nil)

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      refute html =~ "Agenda"
    end

    test "the location field takes priority over the imported address", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:location, "MassDot")
        |> Map.put(:imported_address, "Meet me at the docks")

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      assert html =~ event.location
      refute html =~ "Meet me at the docks"
    end

    test "given the location field is empty, the imported address is shown", %{conn: conn} do
      event =
        event_factory()
        |> Map.put(:location, nil)
        |> Map.put(:imported_address, "Meet me at the docks")

      html =
        Site.EventView
        |> render_to_string("show.html", conn: conn, event: event)

      assert html =~ "Meet me at the docks"
    end
  end

  describe "calendar_title/1" do
    test "returns the name of the month" do
      assert calendar_title("2017-01-01") == "January"
    end
  end

  describe "no_results_message/1" do
    test "includes the name of the month" do
      expected_message = "Sorry, there are no events in January."

      assert no_results_message("2017-01-01") == expected_message
    end
  end

  describe "shift_date_range/2" do
    test "shifts the month by the provided value" do
      assert shift_date_range("2017-04-15", -1) == "2017-03-01"
    end

    test "returns the beginning of the month" do
      assert shift_date_range("2017-04-15", 1) == "2017-05-01"
    end
  end

  describe "city_and_state" do
    test "returns the city and state, separated by a comma" do
      event =
        event_factory()
        |> Map.put(:city, "Charleston")
        |> Map.put(:state, "South Carolina")

      assert city_and_state(event) == "Charleston, South Carolina"
    end

    test "when the city is not provided" do
      event =
        event_factory()
        |> Map.put(:city, nil)

      assert city_and_state(event) == nil
    end

    test "when the state is not provided" do
      event =
        event_factory()
        |> Map.put(:state, nil)

      assert city_and_state(event) == nil
    end
  end
end
