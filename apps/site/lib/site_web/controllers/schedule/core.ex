defmodule SiteWeb.ScheduleController.Core do
  @moduledoc """
  Core pipeline for schedules
  """
  use Plug.Builder
  import SiteWeb.ControllerHelpers, only: [call_plug: 2, assign_alerts: 2]

  plug(:schedule_pipeline_setup)
  plug(:schedule_pipeline_with_direction)
  plug(SiteWeb.ScheduleController.OriginDestination)
  plug(SiteWeb.ScheduleController.ExcludedStops)
  plug(SiteWeb.ScheduleController.PreSelect)
  plug(SiteWeb.ScheduleController.VehicleLocations)
  plug(SiteWeb.ScheduleController.Predictions)
  plug(SiteWeb.ScheduleController.VehicleTooltips)

  defp schedule_pipeline_setup(conn, _opts) do
    conn
    |> call_plug(SiteWeb.ScheduleController.DatePicker)
    |> call_plug(SiteWeb.ScheduleController.Defaults)
    |> call_plug(SiteWeb.ScheduleController.RouteBreadcrumbs)
  end

  defp schedule_pipeline_with_direction(conn, _opts) do
    conn
    |> assign_alerts([])
    |> call_plug(SiteWeb.ScheduleController.AllStops)
  end
end
