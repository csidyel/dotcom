defmodule TripPlan.Leg do
  @moduledoc """
  A single-mode part of an Itinerary

  An Itinerary can take multiple modes of transportation (walk, bus,
  train, &c). Leg represents a single mode of travel during journey.
  """
  alias TripPlan.{PersonalDetail, TransitDetail, NamedPosition}

  defstruct start: DateTime.from_unix!(-1),
            stop: DateTime.from_unix!(0),
            mode: nil,
            from: nil,
            to: nil,
            polyline: ""

  @type mode :: PersonalDetail.t() | TransitDetail.t()
  @type t :: %__MODULE__{
          start: DateTime.t(),
          stop: DateTime.t(),
          mode: mode,
          from: NamedPosition.t(),
          to: NamedPosition.t(),
          polyline: String.t()
        }

  @doc "Returns the route ID for the leg, if present"
  @spec route_id(t) :: {:ok, Routes.Route.id_t()} | :error
  def route_id(%__MODULE__{mode: %TransitDetail{route_id: route_id}}), do: {:ok, route_id}
  def route_id(%__MODULE__{}), do: :error

  @doc "Returns the trip ID for the leg, if present"
  @spec trip_id(t) :: {:ok, Schedules.Trip.id_t()} | :error
  def trip_id(%__MODULE__{mode: %TransitDetail{trip_id: trip_id}}), do: {:ok, trip_id}
  def trip_id(%__MODULE__{}), do: :error

  @spec route_trip_ids(t) :: {:ok, {Routes.Route.id_t(), Schedules.Trip.id_t()}} | :error
  def route_trip_ids(%__MODULE__{mode: %TransitDetail{} = mode}) do
    {:ok, {mode.route_id, mode.trip_id}}
  end

  def route_trip_ids(%__MODULE__{}) do
    :error
  end

  @doc "Determines if this leg uses public transit"
  @spec transit?(t) :: boolean
  def transit?(%__MODULE__{mode: %PersonalDetail{}}), do: false
  def transit?(%__MODULE__{mode: %TransitDetail{}}), do: true

  @spec walking_distance(t) :: float
  def walking_distance(%__MODULE__{mode: %PersonalDetail{distance: distance}}), do: distance
  def walking_distance(%__MODULE__{mode: %TransitDetail{}}), do: 0.0

  @doc "Returns the stop IDs for the leg"
  @spec stop_ids(t) :: [Stops.Stop.id_t()]
  def stop_ids(%__MODULE__{from: from, to: to}) do
    for %NamedPosition{stop_id: stop_id} <- [from, to],
        stop_id do
      stop_id
    end
  end

  @doc "Determines if two legs have the same to and from fields"
  @spec same_leg?(t, t) :: boolean
  def same_leg?(%__MODULE__{from: from, to: to}, %__MODULE__{from: from, to: to}), do: true
  def same_leg?(_leg_1, _leg_2), do: false
end
