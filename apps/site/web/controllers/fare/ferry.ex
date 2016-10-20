defmodule Site.FareController.Ferry do
  use Site.Fare.FareBehaviour

  alias Schedules.Stop

  def route_type, do: 4

  def mode_name, do: "Ferry"

  def fares(%Stop{id: origin}, %Stop{id: destination})
  when "Boat-Charlestown" in [origin, destination] and "Boat-Logan" in [origin, destination]
    do
    Fares.Repo.all(name: :ferry_cross_harbor)
  end
  def fares(%Stop{id: origin}, %Stop{id: destination}) when "Boat-Charlestown" in [origin, destination] do
    Fares.Repo.all(name: :ferry_inner_harbor)
  end
  def fares(%Stop{id: origin}, %Stop{id: destination}) when "Boat-Logan" in [origin, destination] do
    Fares.Repo.all(name: :commuter_ferry_logan)
  end
  def fares(origin, destination) when not is_nil(origin) and not is_nil(destination) do
    Fares.Repo.all(name: :commuter_ferry)
  end
  def fares(_origin, _destination) do
    []
  end

  def key_stops, do: []
end
