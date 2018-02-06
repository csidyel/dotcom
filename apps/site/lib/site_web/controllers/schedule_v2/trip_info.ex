defmodule SiteWeb.ScheduleV2Controller.TripInfo do
  @moduledoc """

  Assigns :trip_info to either a TripInfo struct or nil, depending on whether
  there's a trip we want to display.

  """
  @behaviour Plug
  alias Plug.Conn
  import Plug.Conn, only: [assign: 3, halt: 1]
  import Phoenix.Controller, only: [redirect: 2]
  import UrlHelpers, only: [update_url: 2]
  import SiteWeb.ScheduleV2Controller.ClosedStops, only: [add_wollaston: 4]

  require Routes.Route
  alias Routes.Route
  alias SiteWeb.ScheduleV2Controller.VehicleLocations

  @default_opts [
    trip_fn: &Schedules.Repo.schedule_for_trip/2,
    vehicle_fn: &Vehicles.Repo.trip/1,
    prediction_fn: &Predictions.Repo.all/1
  ]

  @impl true
  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  @impl true
  def call(conn, opts) do
    case trip_id(conn) do
      nil ->
        assign(conn, :trip_info, nil)
      selected_trip_id ->
        expanded = conn.query_params["expanded"]

        conn
        |> assign(:expanded, expanded)
        |> handle_trip(selected_trip_id, opts)
    end
  end

  # Returns the selected trip ID based on the conn's query params or journeys.
  @spec trip_id(Conn.t) :: String.t | nil
  defp trip_id(%Conn{query_params: %{"trip" => ""}}) do
    # explicitly selected no trip
    nil
  end
  defp trip_id(%Conn{query_params: %{"trip" => trip_id}}) do
    trip_id
  end
  defp trip_id(%Conn{assigns:
                %{journeys: %JourneyList{journeys: journeys},
                  route: route,
                  date: user_selected_date,
                  date_time: date_time}}) when journeys != [] do
    if show_trips?(user_selected_date, date_time, route.type, route.id) do
      current_trip(journeys, date_time)
    else
      nil
    end
  end
  defp trip_id(%Conn{assigns: %{journeys: %JourneyList{journeys: journeys}, date_time: date_time}})
  when journeys != [] do
    current_trip(journeys, date_time)
  end
  defp trip_id(%Conn{}) do
    nil
  end

  defp handle_trip(conn, selected_trip_id, opts) do
    case build_info(selected_trip_id, conn, opts) do
      {:error, _} ->
        possibly_remove_trip_query(conn)
      info ->
        assign_trip_info(conn, info)
    end
  end

  defp assign_trip_info(%{assigns: %{route: %{id: "Red"}}} = conn, %{times: times} = info) do
    assign(conn, :trip_info,
           %{info | times: add_wollaston(times, direction_id(times),
                                         &PredictedSchedule.stop/1, &PredictedSchedule.put_stop/2)})
  end
  defp assign_trip_info(conn, info) do
    assign(conn, :trip_info, info)
  end

  defp direction_id(times) do
    times
    |> List.first()
    |>  PredictedSchedule.direction_id()
  end

  defp possibly_remove_trip_query(%{query_params: %{"trip" => _}} = conn) do
    url = update_url(conn, trip: nil)
    conn
    |> redirect(to: url)
    |> halt
  end
  defp possibly_remove_trip_query(conn) do
    assign(conn, :trip_info, nil)
  end

  defp build_info(trip_id, conn, opts) do
    # Compute the active stop that matches the one computed by the tooltips
    active_stop = VehicleLocations.active_stop(conn.assigns.vehicle_locations, trip_id)

    with trips when is_list(trips) <- opts[:trip_fn].(trip_id, date: conn.assigns.date) do
      trips
      |> build_trip_times(conn.assigns, trip_id, opts[:prediction_fn])
      |> TripInfo.from_list(
        vehicle: opts[:vehicle_fn].(trip_id),
        vehicle_stop_name: active_stop,
        origin_id: conn.query_params["origin"],
        destination_id: conn.query_params["destination"])
    end
  end

  # If there are more trips left in a day, finds the next trip based on the current time.
  @spec current_trip([Journey.t], DateTime.t) :: String.t | nil
  defp current_trip([%Journey{} | _] = times, now) do
    do_current_trip times, now
  end
  defp current_trip([], _now), do: nil

  @spec do_current_trip([Journey.t], DateTime.t) :: String.t | nil
  defp do_current_trip(times, now) do
    case Enum.find(times, &is_trip_after_now?(&1, now)) do
      nil -> nil
      time -> PredictedSchedule.trip(time.departure).id
    end
  end

  @spec is_trip_after_now?(Journey.t, DateTime.t) :: boolean
  defp is_trip_after_now?(%Journey{departure: departure}, now) do
    # returns true if the Journey has a trip that's departing in the future
    PredictedSchedule.map_optional(departure, [:prediction, :schedule], false, fn x ->
      if x.time && x.trip do
        compare(x.time, now) == :gt
      else
        false
      end
    end)
  end

  defp compare(%DateTime{} = a, %DateTime{} = b) do
    DateTime.compare(a, b)
  end
  defp compare(%NaiveDateTime{} = a, %NaiveDateTime{} = b) do
    NaiveDateTime.compare(a, b)
  end

  defp build_trip_times(schedules, %{date_time: date_time} = assigns, trip_id, prediction_fn) do
    assigns
    |> get_trip_predictions(Util.service_date(date_time), trip_id, prediction_fn)
    |> PredictedSchedule.group(schedules)
  end

  defp get_trip_predictions(%{date: date}, service_date, _, _prediction_fn)
  when date != service_date do
    []
  end
  defp get_trip_predictions(_, _, trip_id, prediction_fn) do
    prediction_fn.([trip: trip_id])
  end

  @spec show_trips?(DateTime.t, DateTime.t, integer, String.t) :: boolean
  def show_trips?(user_selected_date, current_date_time, route_type, route_id) when Route.subway?(route_type, route_id) do
    Date.diff(user_selected_date, current_date_time) == 0
  end
  def show_trips?(_date, _current_date_time, _route_type, _route_id), do: true
end
