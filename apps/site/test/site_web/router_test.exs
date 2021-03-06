defmodule Phoenix.Router.RoutingTest do
  use SiteWeb.ConnCase, async: true

  describe "redirects" do
    test "yawkey redirect", %{conn: conn} do
      conn = get(conn, "/stops/Lansdowne")
      assert redirected_to(conn, 301) == "/stops/Yawkey"
    end

    test "SL buses", %{conn: conn} do
      conn = get(conn, "/schedules/SL1")
      assert redirected_to(conn, 301) == "/schedules/741"

      conn = get(conn, "/schedules/sl1")
      assert redirected_to(conn, 301) == "/schedules/741"

      conn = get(conn, "/schedules/SL2")
      assert redirected_to(conn, 301) == "/schedules/742"

      conn = get(conn, "/schedules/sl2")
      assert redirected_to(conn, 301) == "/schedules/742"

      conn = get(conn, "/schedules/SL3")
      assert redirected_to(conn, 301) == "/schedules/743"

      conn = get(conn, "/schedules/sl3")
      assert redirected_to(conn, 301) == "/schedules/743"

      conn = get(conn, "/schedules/SL4")
      assert redirected_to(conn, 301) == "/schedules/751"

      conn = get(conn, "/schedules/sl4")
      assert redirected_to(conn, 301) == "/schedules/751"

      conn = get(conn, "/schedules/SL5")
      assert redirected_to(conn, 301) == "/schedules/749"

      conn = get(conn, "/schedules/sl5")
      assert redirected_to(conn, 301) == "/schedules/749"
    end

    test "CT buses", %{conn: conn} do
      conn = get(conn, "/schedules/CT2")
      assert redirected_to(conn, 301) == "/schedules/747"

      conn = get(conn, "/schedules/ct2")
      assert redirected_to(conn, 301) == "/schedules/747"

      conn = get(conn, "/schedules/CT3")
      assert redirected_to(conn, 301) == "/schedules/708"

      conn = get(conn, "/schedules/ct3")
      assert redirected_to(conn, 301) == "/schedules/708"
    end

    test "routes eliminated by Better Bus Project", %{conn: conn} do
      conn = get(conn, "/schedules/CT1")
      assert redirected_to(conn, 301) == "/betterbus-CT1"

      conn = get(conn, "/schedules/CT1/tab")
      assert redirected_to(conn, 301) == "/betterbus-CT1"

      conn = get(conn, "/schedules/ct1")
      assert redirected_to(conn, 301) == "/betterbus-CT1"

      conn = get(conn, "/schedules/ct1/tab")
      assert redirected_to(conn, 301) == "/betterbus-CT1"

      conn = get(conn, "/schedules/701")
      assert redirected_to(conn, 301) == "/betterbus-CT1"

      conn = get(conn, "/schedules/701/tab")
      assert redirected_to(conn, 301) == "/betterbus-CT1"

      conn = get(conn, "/schedules/5")
      assert redirected_to(conn, 301) == "/betterbus-5"

      conn = get(conn, "/schedules/5/tab")
      assert redirected_to(conn, 301) == "/betterbus-5"

      conn = get(conn, "/schedules/459")
      assert redirected_to(conn, 301) == "/betterbus-455-459"

      conn = get(conn, "/schedules/459/tab")
      assert redirected_to(conn, 301) == "/betterbus-455-459"

      conn = get(conn, "/schedules/448")
      assert redirected_to(conn, 301) == "/betterbus-440s"

      conn = get(conn, "/schedules/448/tab")
      assert redirected_to(conn, 301) == "/betterbus-440s"

      conn = get(conn, "/schedules/449")
      assert redirected_to(conn, 301) == "/betterbus-440s"

      conn = get(conn, "/schedules/449/tab")
      assert redirected_to(conn, 301) == "/betterbus-440s"
    end
  end
end
