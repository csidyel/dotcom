defmodule Alerts.Cache.FetcherTest do
  use ExUnit.Case, async: true

  alias Alerts.Cache.Fetcher

  test "It periodically polls an API and updates the store" do
    {:ok, fake_store} = Agent.start_link(fn -> [] end)
    update_fn = make_update_fn(fake_store, self())
    api_fn = fn() -> valid_data() end

    {:ok, fetcher} = Fetcher.start_link(api_fn: api_fn, update_fn: update_fn, repeat_ms: 10_000)
    send(fetcher, :fetch)
    send(fetcher, :fetch)
    send(fetcher, :fetch)
    _ = await_updated()
    _ = await_updated()
    _ = await_updated()

    updates = Agent.get(fake_store, & &1)
    assert [{[%Alerts.Alert{}], nil}, {[%Alerts.Alert{}], nil}, {[%Alerts.Alert{}], nil}] = updates
  end

  test "It handles a failed API response and does not update the store" do
    {:ok, fake_store} = Agent.start_link(fn -> [] end)
    update_fn = make_update_fn(fake_store, self())
    api_fn = fn() -> {:error, "Didn't work!"} end

    {:ok, fetcher} = Fetcher.start_link(api_fn: api_fn, update_fn: update_fn, repeat_ms: 10_000)
    send(fetcher, :fetch)
    send(fetcher, :fetch)
    _ = await_updated()
    _ = await_updated()

    updates = Agent.get(fake_store, & &1)
    assert updates == []
  end

  test "It handles unexpected messages" do
    {:ok, fake_store} = Agent.start_link(fn -> [] end)
    update_fn = make_update_fn(fake_store, self())
    api_fn = fn() -> valid_data() end

    {:ok, fetcher} = Fetcher.start_link(api_fn: api_fn, update_fn: update_fn, repeat_ms: 10_000)
    send(fetcher, :fetch)
    send(fetcher, :unexpected)
    send(fetcher, :fetch)
    _ = await_updated()
    _ = await_updated()

    updates = Agent.get(fake_store, & &1)
    assert [{[%Alerts.Alert{}], nil}, {[%Alerts.Alert{}], nil}] = updates
  end

  defp valid_data do
    %JsonApi{data: [
      %JsonApi.Item{
        attributes: %{
          "active_period" => [%{"end" => nil, "start" => "2017-05-01T04:30:00-04:00"}],
          "banner" => nil,
          "cause" => "CONSTRUCTION",
          "created_at" => "2016-10-21T13:45:28-04:00",
          "description" => "The Description",
          "effect" => "UNKNOWN_EFFECT",
          "effect_name" => "Service Change",
          "header" => "The header.",
          "informed_entity" => [
            %{"route" => "CR-Fitchburg", "route_type" => 2},
            %{"route" => "CR-Haverhill", "route_type" => 2},
            %{"route" => "CR-Lowell", "route_type" => 2},
            %{"route" => "CR-Newburyport", "route_type" => 2}
          ],
          "lifecycle" => "New",
          "service_effect" => "Commuter Rail notice",
          "severity" => "Minor",
          "short_header" => "Short header",
          "timeframe" => nil,
          "updated_at" => "2017-04-25T21:30:28-04:00",
          "url" => nil
        },
        id: "152291",
        relationships: %{},
        type: "alert"
      }
    ]}
  end

  defp make_update_fn(agent, pid) do
    fn(alerts, banner) ->
      Agent.update(agent, fn updates -> [{alerts, banner} | updates] end)
      send(pid, :updated)
    end
  end

  defp await_updated do
    receive do
      :updated -> :ok
    after
      1_000 -> :no_msg
    end
  end
end
