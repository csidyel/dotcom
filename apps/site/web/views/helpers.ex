defmodule Site.ViewHelpers do
  import Site.Router.Helpers

  def svg(_conn, path) do
    svg_content = :site
    |> Application.app_dir
    |> Path.join("priv/static" <> path)
    |> File.read!
    |> String.split("\n")
    |> Enum.join("")

    Phoenix.HTML.raw svg_content
  end

  def redirect_path(conn, path) do
    redirect_path(conn, :show, path)
  end

  def google_api_key do
    env(:google_api_key)
  end

  def font_awesome_id do
    env(:font_awesome_id)
  end

  defp env(key) do
    Application.get_env(:site, __MODULE__)[key]
  end

  @doc "The string description of a direction ID"
  def direction(0), do: "Outbound"
  def direction(1), do: "Inbound"
  def direction(_), do: "Unknown"
end
