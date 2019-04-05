defmodule Content.RepoTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog, only: [capture_log: 1]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Mock

  # Content Types
  alias Content.{
    Banner,
    Event,
    GenericPage,
    LandingPage,
    NewsEntry,
    Project,
    ProjectUpdate,
    Redirect,
    WhatsHappeningItem
  }

  # Misc
  alias Content.{
    CMS.Static,
    Paragraph,
    Repo,
    RoutePdf,
    Teaser
  }

  describe "news_entry_by/1" do
    test "returns the news entry for the given id" do
      assert %NewsEntry{id: 3519} = Repo.news_entry_by(id: 3519)
    end

    test "returns :not_found given no record is found" do
      assert :not_found == Repo.news_entry_by(id: 999)
    end
  end

  describe "get_page/1" do
    test "caches views" do
      path = "/news/2018/news-entry"
      params = %{}
      cache_key = {:view_or_preview, path: path, params: params}

      # ensure cache is empty
      case ConCache.get(Repo, cache_key) do
        nil ->
          :ok

        {:ok, %{"type" => [%{"target_id" => "news_entry"}]}} ->
          ConCache.dirty_delete(Repo, cache_key)
      end

      assert %NewsEntry{} = Repo.get_page(path, params)
      assert {:ok, %{"type" => [%{"target_id" => "news_entry"}]}} = ConCache.get(Repo, cache_key)
    end

    test "does not cache previews" do
      path = "/basic_page_no_sidebar"
      params = %{"preview" => "", "vid" => "112", "nid" => "6"}
      cache_key = {:view_or_preview, path: path, params: params}
      assert ConCache.get(Repo, cache_key) == nil
      assert %GenericPage{} = Repo.get_page(path, params)
      assert ConCache.get(Repo, cache_key) == nil
    end

    test "given the path for a Basic page" do
      result = Repo.get_page("/basic_page_with_sidebar")
      assert %GenericPage{} = result
    end

    test "returns a NewsEntry" do
      assert %NewsEntry{} = Repo.get_page("/news/2018/news-entry")
    end

    test "returns an Event" do
      assert %Event{} = Repo.get_page("/events/date/title")
    end

    test "returns a Project" do
      assert %Project{} = Repo.get_page("/projects/project-name")
    end

    test "returns a ProjectUpdate" do
      assert %ProjectUpdate{} = Repo.get_page("/projects/project-name/update/project-progress")
    end

    test "given the path for a Basic page with tracking params" do
      result = Repo.get_page("/basic_page_with_sidebar", %{"from" => "search"})
      assert %GenericPage{} = result
    end

    test "given the path for a Landing page" do
      result = Repo.get_page("/landing_page")
      assert %LandingPage{} = result
    end

    test "given the path for a Redirect page" do
      result = Repo.get_page("/redirect_node")
      assert %Redirect{} = result
    end

    test "returns {:error, :not_found} when the path does not match an existing page" do
      assert Repo.get_page("/does/not/exist") == {:error, :not_found}
    end

    test "returns {:error, :invalid_response} when the CMS returns a server error" do
      assert Repo.get_page("/cms/route-pdfs/error") == {:error, :invalid_response}
    end

    test "returns {:error, :invalid_response} when JSON is invalid" do
      assert Repo.get_page("/invalid") == {:error, :invalid_response}
    end

    test "given special preview query params, return certain revision of node" do
      result =
        Repo.get_page("/basic_page_no_sidebar", %{"preview" => "", "vid" => "112", "nid" => "6"})

      assert %GenericPage{} = result
      assert result.title == "Arts on the T 112"
    end

    test "deprecated use of 'latest' value for revision parameter still returns newest revision" do
      result =
        Repo.get_page("/basic_page_no_sidebar", %{
          "preview" => "",
          "vid" => "latest",
          "nid" => "6"
        })

      assert %GenericPage{} = result
      assert result.title == "Arts on the T 113"
    end
  end

  describe "get_page_with_encoded_id/2" do
    test "encodes the id param into the request" do
      assert Repo.get_page("/redirect_node_with_query", %{"id" => "5"}) == {:error, :not_found}

      assert %Redirect{} =
               Repo.get_page_with_encoded_id("/redirect_node_with_query", %{"id" => "5"})
    end
  end

  describe "events/1" do
    test "returns list of Event" do
      assert [
               %Event{
                 id: id,
                 body: body
               }
               | _
             ] = Repo.events()

      assert id == 3268

      assert safe_to_string(body) =~
               "(FMCB) closely monitors the T’s finances, management, and operations.</p>"
    end
  end

  describe "event_by/1" do
    test "returns the event for the given id" do
      assert %Event{id: 3268} = Repo.event_by(id: 3268)
    end

    test "returns :not_found given no record is found" do
      assert :not_found == Repo.event_by(id: 999)
    end
  end

  describe "whats_happening" do
    test "returns a list of WhatsHappeningItem" do
      assert [
               %WhatsHappeningItem{
                 blurb: blurb
               }
               | _
             ] = Repo.whats_happening()

      assert blurb =~
               "Visiting Boston? Find your way around with our new Visitor's Guide to the T."
    end
  end

  describe "banner" do
    test "returns a Banner" do
      assert %Banner{
               blurb: blurb
             } = Repo.banner()

      assert blurb == "Headline goes here"
    end
  end

  describe "search" do
    test "with results" do
      {:ok, result} = Repo.search("mbta", 0, [])
      assert result.count == 2083
    end

    test "without results" do
      {:ok, result} = Repo.search("empty", 0, [])
      assert result.count == 0
    end
  end

  describe "get_route_pdfs/1" do
    test "returns list of RoutePdfs" do
      assert [%RoutePdf{}, _, _] = Repo.get_route_pdfs("87")
    end

    test "returns empty list if there's an error" do
      log =
        capture_log(fn ->
          assert [] = Repo.get_route_pdfs("error")
        end)

      assert log =~ "Error getting pdfs"
    end

    test "returns empty list if there's no pdfs for the route id" do
      assert [] = Repo.get_route_pdfs("doesntexist")
    end
  end

  describe "teasers/1" do
    test "returns only teasers for a project type" do
      types =
        [type: :project]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:project]
    end

    test "returns all teasers for a type that are sticky" do
      teasers =
        [type: :project, sticky: 1]
        |> Repo.teasers()

      assert [%Teaser{}, %Teaser{}, %Teaser{}] = teasers
    end

    test "returns all teasers for a route" do
      types =
        [route_id: "Red", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a topic" do
      types =
        [topic: "Guides", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a mode" do
      types =
        [mode: "subway", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a mode and topic combined" do
      types =
        [mode: "subway", topic: "Guides", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "returns all teasers for a route_id and topic combined" do
      types =
        [route_id: "Red", topic: "Guides", sidebar: 1]
        |> Repo.teasers()
        |> MapSet.new(& &1.type)
        |> MapSet.to_list()

      assert types == [:event, :news_entry, :project]
    end

    test "converts generic arguments into path parts for API request" do
      mock_view = fn
        "/cms/teasers/Guides/Red", %{sticky: 0} -> {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(args: ["Guides", "Red"], sticky: 0)

        "/cms/teasers/Guides/Red"
        |> Static.view(%{sticky: 0})
        |> assert_called()
      end
    end

    test "takes a :type option" do
      teasers = Repo.teasers(route_id: "Red", type: :project, sidebar: 1)
      assert Enum.all?(teasers, &(&1.type == :project))
    end

    test "takes a :type_op option" do
      all_teasers = Repo.teasers(route_id: "Red", sidebar: 1)
      assert Enum.any?(all_teasers, &(&1.type == :project))

      filtered = Repo.teasers(route_id: "Red", type: :project, type_op: "not in", sidebar: 1)
      refute Enum.empty?(filtered)
      refute Enum.any?(filtered, &(&1.type == :project))
    end

    test "takes an :items_per_page option" do
      all_teasers = Repo.teasers(route_id: "Red", sidebar: 1)
      assert Enum.count(all_teasers) > 1
      assert [%Teaser{}] = Repo.teasers(route_id: "Red", items_per_page: 1)
    end

    test "takes a :related_to option" do
      mock_view = fn
        "/cms/teasers", %{related_to: 123} -> {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(related_to: 123)

        "/cms/teasers"
        |> Static.view(%{related_to: 123})
        |> assert_called()
      end
    end

    test "takes an :except option" do
      mock_view = fn
        "/cms/teasers", %{except: 123} -> {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(except: 123)

        "/cms/teasers"
        |> Static.view(%{except: 123})
        |> assert_called()
      end
    end

    test "takes an :only option" do
      mock_view = fn
        "/cms/teasers", %{only: 123} -> {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(only: 123)

        "/cms/teasers"
        |> Static.view(%{only: 123})
        |> assert_called()
      end
    end

    test "takes a :date and :date_op option" do
      mock_view = fn
        "/cms/teasers", %{date: "2018-01-01", date_op: ">="} -> {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(date: "2018-01-01", date_op: ">=")

        "/cms/teasers"
        |> Static.view(%{date: "2018-01-01", date_op: ">="})
        |> assert_called()
      end
    end

    test "sets correct :sort_by and :sort_order options for project_update and news_entry requests" do
      mock_view = fn
        "/cms/teasers",
        %{type: :project_update, sort_by: "field_posted_on_value", sort_order: :DESC} ->
          {:ok, []}

        "/cms/teasers",
        %{type: :news_entry, sort_by: "field_posted_on_value", sort_order: :ASC} ->
          {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(type: :project_update)
        Repo.teasers(type: :news_entry, sort_order: :ASC)

        "/cms/teasers"
        |> Static.view(%{
          type: :project_update,
          sort_by: "field_posted_on_value",
          sort_order: :DESC
        })
        |> assert_called()

        "/cms/teasers"
        |> Static.view(%{
          type: :news_entry,
          sort_by: "field_posted_on_value",
          sort_order: :ASC
        })
        |> assert_called()
      end
    end

    test "sets correct :sort_by and :sort_order options for project requests" do
      mock_view = fn
        "/cms/teasers", %{type: :project, sort_by: "field_updated_on_value", sort_order: :DESC} ->
          {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(type: :project)

        "/cms/teasers"
        |> Static.view(%{type: :project, sort_by: "field_updated_on_value", sort_order: :DESC})
        |> assert_called()
      end
    end

    test "sets correct :sort_by and :sort_order options for event requests" do
      mock_view = fn
        "/cms/teasers", %{type: :event, sort_by: "field_start_time_value", sort_order: :DESC} ->
          {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(type: :event)

        "/cms/teasers"
        |> Static.view(%{type: :event, sort_by: "field_start_time_value", sort_order: :DESC})
        |> assert_called()
      end
    end

    test "drops :sort_by and :sort_order options for invalid sortable types" do
      mock_view = fn
        "/cms/teasers", %{type: :page} ->
          {:ok, []}
      end

      with_mock Static, view: mock_view do
        Repo.teasers(type: :page, sort_by: :ASC)

        "/cms/teasers"
        |> Static.view(%{type: :page})
        |> assert_called()
      end
    end

    test "returns an empty list and logs a warning if there is an error" do
      log =
        capture_log(fn ->
          assert Repo.teasers(route_id: "NotFound", sidebar: 1) == []
        end)

      assert log =~ "error=:not_found"
    end
  end

  describe "get_paragraph/1" do
    test "returns a single paragraph item" do
      paragraph = Repo.get_paragraph(30)
      assert %Paragraph.CustomHTML{} = paragraph
    end
  end
end
