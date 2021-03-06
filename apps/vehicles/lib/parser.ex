defmodule Vehicles.Parser do
  alias Vehicles.Vehicle

  @spec parse(JsonApi.Item.t()) :: Vehicle.t()
  def parse(%JsonApi.Item{id: id, attributes: attributes, relationships: relationships}) do
    %Vehicle{
      id: id,
      route_id: optional_id(relationships["route"]),
      trip_id: optional_id(relationships["trip"]),
      shape_id: shape(relationships["trip"]),
      stop_id: stop_id(relationships["stop"]),
      direction_id: attributes["direction_id"],
      status: status(attributes["current_status"]),
      longitude: attributes["longitude"],
      latitude: attributes["latitude"],
      bearing: attributes["bearing"] || 0
    }
  end

  @spec status(String.t()) :: Vehicle.status()
  defp status("STOPPED_AT"), do: :stopped
  defp status("INCOMING_AT"), do: :incoming
  defp status("IN_TRANSIT_TO"), do: :in_transit

  @spec optional_id([JsonApi.Item.t()]) :: String.t() | nil
  defp optional_id([]), do: nil
  defp optional_id([%JsonApi.Item{id: id}]), do: id

  @spec stop_id([JsonApi.Item.t()]) :: String.t()
  defp stop_id([%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{id: stop_id}]}}]) do
    stop_id
  end

  defp stop_id([%JsonApi.Item{id: stop_id}]) do
    stop_id
  end

  defp stop_id([]) do
    nil
  end

  @spec shape([JsonApi.Item.t()]) :: String.t() | nil
  defp shape([%JsonApi.Item{relationships: %{"shape" => [%{id: id} | _]}} | _]) do
    id
  end

  defp shape(_) do
    nil
  end
end
