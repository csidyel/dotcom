defmodule Util.BreadcrumbHTMLTest do
  use ExUnit.Case, async: true
  import Util.BreadcrumbHTML

  setup do
    {:ok, conn: %Plug.Conn{}}
  end

  describe "title_breadcrumbs/1" do
    test "returns the text for each breadcrumb, in reverse order", %{conn: conn} do
      breadcrumbs = [
        %Util.Breadcrumb{text: "Home", url: "/"},
        %Util.Breadcrumb{text: "Second", url: "/second"}
      ]
      conn = Plug.Conn.assign(conn, :breadcrumbs, breadcrumbs)

      breadcrumbs = conn |> title_breadcrumbs |> IO.iodata_to_binary
      assert breadcrumbs =~ "Second < Home"
    end

    test "appends the MBTA's name", %{conn: conn} do
      breadcrumbs = [%Util.Breadcrumb{text: "Home", url: "/"}]
      conn = Plug.Conn.assign(conn, :breadcrumbs, breadcrumbs)

      breadcrumbs = conn |> title_breadcrumbs |> IO.iodata_to_binary
      assert breadcrumbs == "Home < MBTA - Massachusetts Bay Transportation Authority"

    end

    test "returns the MBTA's name when breadcrumbs are empty", %{conn: conn} do
      conn = Plug.Conn.assign(conn, :breadcrumbs, [])
      breadcrumbs = conn |> title_breadcrumbs |> IO.iodata_to_binary
      assert breadcrumbs == "MBTA - Massachusetts Bay Transportation Authority"
    end

    test "returns the MBTA's name when the breadcrumbs key is not found", %{conn: conn} do
      breadcrumbs = conn |> title_breadcrumbs |> IO.iodata_to_binary
      assert breadcrumbs == "MBTA - Massachusetts Bay Transportation Authority"
    end
  end

  describe "breadcrumb_trail/1" do
    test "generates safe html for breadcrumbs", %{conn: conn} do
      breadcrumbs = [
        %Util.Breadcrumb{text: "Home", url: "/"},
        %Util.Breadcrumb{text: "Second", url: ""}
      ]

      conn = Plug.Conn.assign(conn, :breadcrumbs, breadcrumbs)

      assert breadcrumb_trail(conn) == {:safe,
        ~s(<span>) <>
        ~s(<a href="/">Home</a>) <>
        ~s(<i class="fa fa-angle-right" aria-hidden="true"></i>) <>
        ~s(</span>) <>
        ~s(Second)
      }
    end

    test "adds a link to the root path if one is not provided", %{conn: conn} do
      breadcrumbs = [%Util.Breadcrumb{text: "Not Home", url: "/not-home"}]
      conn = Plug.Conn.assign(conn, :breadcrumbs, breadcrumbs)

      result = breadcrumb_trail(conn)

      assert Phoenix.HTML.safe_to_string(result) =~
        ~s(<span>) <>
        ~s(<a href="/">Home</a>) <>
        ~s(<i class="fa fa-angle-right" aria-hidden="true"></i>) <>
        ~s(</span>)
    end

    test "when the breadcrumbs are empty", %{conn: conn} do
      conn = Plug.Conn.assign(conn, :breadcrumbs, [])
      assert breadcrumb_trail(conn) == {:safe, ""}
    end

    test "when the breadcrumbs key is not found", %{conn: conn} do
      assert breadcrumb_trail(conn) == {:safe, ""}
    end
  end

  describe "build_html/2" do
    test "returns html for a breadcrumb", %{conn: conn} do
      breadcrumbs = [%Util.Breadcrumb{text: "home", url: "sample"}]

      assert build_html(breadcrumbs, conn) == [
        ~s(<a href="sample">home</a>)
      ]
    end

    test "separates each breadcrumb with an icon", %{conn: conn} do
      breadcrumbs = [
        %Util.Breadcrumb{text: "Home", url: "/"},
        %Util.Breadcrumb{text: "Second", url: ""}
      ]

      [first_crumb, second_crumb] = build_html(breadcrumbs, conn)

      assert first_crumb ==
        ~s(<span>) <>
        ~s(<a href="/">Home</a>) <>
        ~s(<i class="fa fa-angle-right" aria-hidden="true"></i>) <>
        ~s(</span>)

      assert second_crumb == "Second"
    end

    test "includes a 'collapse on mobile' class for breadcrumbs except the last two", %{conn: conn} do
      breadcrumbs = [
        %Util.Breadcrumb{text: "Home", url: "/"},
        %Util.Breadcrumb{text: "Second", url: "/second"},
        %Util.Breadcrumb{text: "Third", url: "/third"}
      ]

      [first_crumb, second_crumb, third_crumb] = build_html(breadcrumbs, conn)

      assert first_crumb ==
        ~s(<span class="focusable-sm-down">) <>
        ~s(<a href="/">Home</a>) <>
        ~s(<i class="fa fa-angle-right" aria-hidden="true"></i>) <>
        ~s(</span>)

      refute Regex.match?(~r/focusable-sm-down/, second_crumb)
      refute Regex.match?(~r/focusable-sm-down/, third_crumb)
    end
  end

  describe "maybe_add_home_breadcrumb/1" do
    test "adds a link to the home path if one does not exist" do
      assert maybe_add_home_breadcrumb([]) == [
        %Util.Breadcrumb{text: "Home", url: "/"}
      ]
    end

    test "does not add a link to the home path if one already exists" do
      breadcrumb = %Util.Breadcrumb{url: "/foo", text: "foo"}

      assert maybe_add_home_breadcrumb([breadcrumb]) == [
        %Util.Breadcrumb{text: "Home", url: "/"},
        breadcrumb
      ]
    end
  end
end
