defmodule SiteWeb.ControllerHelpersTest do
  use SiteWeb.ConnCase, async: true
  import SiteWeb.ControllerHelpers

  import Plug.Conn,
    only: [
      assign: 3,
      get_resp_header: 2,
      resp: 3,
      merge_resp_headers: 2,
      put_private: 3
    ]

  describe "filter_modes/2" do
    test "filters the key routes of all modes that are passed" do
      routes = [
        {:subway,
         [
           %Routes.Route{
             direction_names: %{0 => "South", 1 => "North"},
             id: "Red",
             description: :rapid_transit,
             name: "Red Line",
             type: 1
           },
           %Routes.Route{
             direction_names: %{0 => "Outbound", 1 => "Inbound"},
             id: "Mattapan",
             description: :rapid_transit,
             name: "Mattapan Trolley",
             type: 0
           }
         ]},
        {:bus,
         [
           %Routes.Route{
             direction_names: %{0 => "Outbound", 1 => "Inbound"},
             id: "22",
             description: :key_bus_route,
             name: "22",
             type: 3
           },
           %Routes.Route{
             direction_names: %{0 => "Outbound", 1 => "Inbound"},
             id: "23",
             description: :key_bus_route,
             name: "23",
             type: 3
           },
           %Routes.Route{
             direction_names: %{0 => "Outbound", 1 => "Inbound"},
             id: "40",
             description: :local_bus,
             name: "40",
             type: 3
           }
         ]}
      ]

      assert filter_routes(routes, [:subway, :bus]) ==
               [
                 {:subway,
                  [
                    %Routes.Route{
                      direction_names: %{0 => "South", 1 => "North"},
                      id: "Red",
                      description: :rapid_transit,
                      name: "Red Line",
                      type: 1
                    },
                    %Routes.Route{
                      direction_names: %{0 => "Outbound", 1 => "Inbound"},
                      id: "Mattapan",
                      description: :rapid_transit,
                      name: "Mattapan Trolley",
                      type: 0
                    }
                  ]},
                 {:bus,
                  [
                    %Routes.Route{
                      direction_names: %{0 => "Outbound", 1 => "Inbound"},
                      id: "22",
                      description: :key_bus_route,
                      name: "22",
                      type: 3
                    },
                    %Routes.Route{
                      direction_names: %{0 => "Outbound", 1 => "Inbound"},
                      id: "23",
                      description: :key_bus_route,
                      name: "23",
                      type: 3
                    }
                  ]}
               ]
    end
  end

  describe "get_grouped_route_ids/1" do
    @grouped_routes [
      subway: [
        %Routes.Route{id: "sub1", type: 0},
        %Routes.Route{id: "sub2", type: 1}
      ],
      bus: [
        %Routes.Route{id: "bus1", type: 3}
      ],
      commuter_rail: [
        %Routes.Route{id: "comm1", type: 2},
        %Routes.Route{id: "comm2", type: 2}
      ]
    ]

    test "returns list of ids from the given grouped routes" do
      assert get_grouped_route_ids(@grouped_routes) == ["sub1", "sub2", "bus1", "comm1", "comm2"]
    end
  end

  describe "assign_alerts/2" do
    @worcester %Alerts.InformedEntity{route: "CR-Worcester", route_type: 2}
    @worcester_inbound %Alerts.InformedEntity{route: "CR-Worcester", direction_id: 1}
    @commuter_rail %Alerts.InformedEntity{route_type: 2}
    @bus %Alerts.InformedEntity{route_type: 3}

    @worcester_alert Alerts.Alert.new(id: "worcester", informed_entity: [@worcester])
    @worcester_inbound_alert Alerts.Alert.new(
                               id: "worcester-inbound",
                               informed_entity: [@worcester_inbound]
                             )
    @commuter_rail_alert Alerts.Alert.new(id: "commuter-rail", informed_entity: [@commuter_rail])
    @bus_alert Alerts.Alert.new(id: "bus", informed_entity: [@bus])

    setup do
      Alerts.Cache.Store.update(
        [@worcester_alert, @worcester_inbound_alert, @commuter_rail_alert, @bus_alert],
        nil
      )
    end

    test "assigns all alerts for the route id, type, and direction", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}

      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, 1)
        |> assign_alerts([])
        |> (fn conn -> conn.assigns.alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, @worcester_inbound_alert]
      assert alerts == expected
    end

    test "does not assign an alert in the opposite direction", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}

      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, 0)
        |> assign_alerts([])
        |> (fn conn -> conn.assigns.alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert]
      assert alerts == expected
    end

    test "assigns alerts for both directions if the direction_id is nil", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}

      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, nil)
        |> assign_alerts([])
        |> (fn conn -> conn.assigns.alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, @worcester_inbound_alert]
      assert alerts == expected
    end

    test "assigns alerts for both directions if the direction_id is not assigned", %{conn: conn} do
      route = %Routes.Route{id: "CR-Worcester", type: 2}

      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign_alerts([])
        |> (fn conn -> conn.assigns.alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, @worcester_inbound_alert]
      assert alerts == expected
    end

    test "assigns alerts when any of the matching informed entities have a nil direction,
          even if others have conflicting direction ids (which shouldn't happen)",
         %{conn: conn} do
      worcester_ambiguous_alert =
        Alerts.Alert.new(
          id: "worcester-ambiguous",
          informed_entity: [@worcester_inbound, @worcester]
        )

      Alerts.Cache.Store.update(
        [
          @worcester_alert,
          @worcester_inbound_alert,
          worcester_ambiguous_alert,
          @commuter_rail_alert,
          @bus_alert
        ],
        nil
      )

      route = %Routes.Route{id: "CR-Worcester", type: 2}

      alerts =
        conn
        |> assign(:date_time, Timex.now())
        |> assign(:route, route)
        |> assign(:direction_id, 0)
        |> assign_alerts([])
        |> (fn conn -> conn.assigns.alerts end).()

      expected = [@commuter_rail_alert, @worcester_alert, worcester_ambiguous_alert]
      assert alerts == expected
    end
  end

  describe "forward_static_file/2" do
    test "returns a 404 if there's an error" do
      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        assert "/causes/an/error" == conn.request_path
        resp(conn, 500, "error on remote server")
      end)

      response =
        forward_static_file(build_conn(), "http://localhost:#{bypass.port}/causes/an/error")

      assert response.status == 404
      assert response.state == :sent
    end

    test "returns a 404 if the remote side returns a 404" do
      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        assert "/does/not/exist" == conn.request_path
        resp(conn, 404, "not found")
      end)

      response =
        forward_static_file(build_conn(), "http://localhost:#{bypass.port}/does/not/exist")

      assert response.status == 404
      assert response.state == :sent
    end

    test "returns the body and headers from the response if it's a 200" do
      headers = [
        {"Content-Type", "text/plain"},
        {"ETag", "tag"},
        {"Content-Length", "6"}
      ]

      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        assert "/this/file/exists" == conn.request_path

        conn
        |> merge_resp_headers(headers)
        |> resp(200, "a file")
      end)

      response =
        forward_static_file(build_conn(), "http://localhost:#{bypass.port}/this/file/exists")

      assert response.status == 200
      assert response.resp_body == "a file"
      assert get_resp_header(response, "content-type") == ["text/plain"]
      assert get_resp_header(response, "etag") == ["tag"]
      assert [date] = get_resp_header(response, "date")
      assert [_wkday, _day, _month, _year, _time, _tz] = String.split(date, " ")
      # we don't pass content-length cuz it causes problems with gzip
      assert get_resp_header(response, "content-length") == []
    end
  end

  describe "render_404/1" do
    test "renders the 404 bus" do
      rendered =
        build_conn()
        |> render_404()
        |> html_response(404)

      assert rendered =~ "Your stop cannot be found."
    end
  end

  describe "check_cms_or_404/1" do
    test "returns existing pages" do
      conn = build_conn(:get, "/basic_page_no_sidebar", nil)

      rendered =
        conn
        |> put_private(:phoenix_endpoint, SiteWeb.Endpoint)
        |> check_cms_or_404()
        |> html_response(200)

      assert rendered =~ "Arts on the T"
    end

    test "404s on nonexistant pages" do
      conn = build_conn(:get, "/this/page/doesnt/exist", nil)

      rendered =
        conn
        |> put_private(:phoenix_endpoint, SiteWeb.Endpoint)
        |> check_cms_or_404()
        |> html_response(404)

      assert rendered =~ "Your stop cannot be found."
    end
  end

  describe "unavailable_after_one_year/1" do
    test "sets an unavailable_after x-robots-tag HTTP header for one year after the given date" do
      conn = build_conn(:get, "/basic_page_no_sidebar", nil)

      transformed_conn = unavailable_after_one_year(conn, ~D[2018-11-13])

      assert {"x-robots-tag", "unavailable_after: 13 Nov 2019 00:00:00 EST"} in transformed_conn.resp_headers
    end

    test "does not set an unavailable_after x-robots-tag HTTP header if no date given" do
      conn = build_conn(:get, "/basic_page_no_sidebar", nil)

      transformed_conn = unavailable_after_one_year(conn, nil)

      refute {"x-robots-tag", "unavailable_after: 13 Nov 2019 00:00:00 EST"} in transformed_conn.resp_headers
    end
  end

  describe "noindex/1" do
    test "sets a noindex x-robots-tag HTTP header" do
      conn = build_conn(:get, "/basic_page_no_sidebar", nil)

      transformed_conn = noindex(conn)

      assert {"x-robots-tag", "noindex"} in transformed_conn.resp_headers
    end
  end

  test "green_routes/0" do
    assert Enum.map(green_routes(), & &1.id) == ["Green-B", "Green-C", "Green-D", "Green-E"]
  end
end
