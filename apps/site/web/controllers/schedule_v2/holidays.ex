defmodule Site.ScheduleV2Controller.Holidays do

  import Plug.Conn, only: [assign: 3]

  def init(opts) do
    Keyword.merge(opts || [], [holiday_limit: 3])
  end

  def call(%Plug.Conn{assigns: %{date: date}} = conn, opts) do
    holidays = date
    |> Holiday.Repo.following
    |> Enum.take(opts[:holiday_limit])

    conn
    |> assign(:holidays, holidays)
  end
  def call(conn, _opts) do
    conn
  end

end
