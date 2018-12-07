defmodule SiteWeb.ScheduleController.Holidays do
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]

  @impl true
  def init(opts) do
    Keyword.merge(opts || [], holiday_limit: 3)
  end

  @impl true
  def call(%Plug.Conn{assigns: %{date: date}} = conn, opts) do
    holidays =
      date
      |> Holiday.Repo.following()
      |> Enum.take(opts[:holiday_limit])

    conn
    |> assign(:holidays, holidays)
  end

  def call(conn, _opts) do
    conn
  end
end
