defmodule Content.PageTest do
  use ExUnit.Case, async: true

  alias Content.{CMS.Static, Page}

  describe "from_api/1" do
    test "switches on the node type in the json response and returns the proper page struct" do
      assert %Content.BasicPage{} = Page.from_api(Static.basic_page_response())
      assert %Content.Event{} = Page.from_api(List.first(Static.events_response()))
      assert %Content.LandingPage{} = Page.from_api(Static.landing_page_response())
      assert %Content.NewsEntry{} = Page.from_api(List.first(Static.news_repo()))
      assert %Content.Person{} = Page.from_api(Static.person_response())
      assert %Content.Project{} = Page.from_api(List.first(Static.project_repo()))
      assert %Content.ProjectUpdate{} = Page.from_api(List.first(Static.project_update_repo()))
      assert %Content.Redirect{} = Page.from_api(Static.redirect_response())
    end
  end
end
