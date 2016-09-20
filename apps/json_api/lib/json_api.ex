defmodule JsonApi.Item do
  defstruct [:type, :id, :attributes, :relationships]
  @type t :: %JsonApi.Item{
    type: String.t,
    id: String.t,
    attributes: %{String.t => String.t},
    relationships: %{String.t => list(JsonApi.Item.t)}}
end

defmodule JsonApi do
  defstruct [:links, :data]
  @type t :: %JsonApi{
    links: %{String.t => String.t},
    data: list(JsonApi.Item.t)}

  @spec empty() :: JsonApi.t
  def empty do
    %JsonApi{
      links: %{},
      data: []
    }
  end

  @spec merge(JsonApi.t, JsonApi.t) :: JsonApi.t
  def merge(j1, j2) do
    %JsonApi{
      links: Map.merge(j1.links, j2.links),
      data: j1.data ++ j2.data
    }
  end

  @spec parse(String.t) :: JsonApi.t | {:error, any}
  def parse(body) do
    with {:ok, parsed} <- Poison.Parser.parse(body) do
      %JsonApi{
        links: parse_links(parsed),
        data: parse_data(parsed)
      }
    end
  end

  @spec parse_links(Poison.Parser.t) :: %{String.t => String.t}
  defp parse_links(%{"links" => links}) do
    links
    |> Enum.filter(fn {key, value} -> is_binary(key) && is_binary(value) end)
    |> Enum.into(%{})
  end
  defp parse_links(_) do
    %{}
  end

  @spec parse_data(Poison.Parser.t) :: list(JsonApi.Item.t)
  defp parse_data(%{"data" => data} = parsed) when is_list(data) do
    included = parse_included(parsed)
    data
    |> Enum.map(&(parse_data_item(&1, included)))
  end
  defp parse_data(%{"data" => data} = parsed) do
    included = parse_included(parsed)
    [parse_data_item(data, included)]
  end
  defp parse_data(%{}) do
    []
  end

  def parse_data_item(%{"type" => type, "id" => id, "attributes" => attributes} = item, included) do
    %JsonApi.Item{
      type: type,
      id: id,
      attributes: attributes,
      relationships: load_relationships(item["relationships"], included)
    }
  end
  def parse_data_item(%{"type" => type, "id" => id}, _) do
    %JsonApi.Item{
      type: type,
      id: id
    }
  end

  defp load_relationships(nil, _) do
    %{}
  end
  defp load_relationships(%{} = relationships, included) do
    relationships
    |> map_values(&(load_single_relationship(&1, included)))
  end

  defp map_values(map, f) do
    map
    |> Map.new(fn {key, value} -> {key, (f).(value)} end)
  end

  defp load_single_relationship(relationship, _) when relationship == %{} do
    []
  end
  defp load_single_relationship(%{"data" => data}, included) when is_list(data) do
    data
    |> Enum.map(&match_included(&1, included))
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&parse_data_item(&1, included))
  end
  defp load_single_relationship(%{"data" => %{} = data}, included) do
    case data |> match_included(included) do
      nil -> []
      item -> [parse_data_item(item, included)]
    end
  end
  defp load_single_relationship(_, _) do
    []
  end

  defp match_included(nil, _) do
    nil
  end
  defp match_included(%{"type" => type, "id" => id} = item, included) do
    Map.get(included, {type, id}, item)
  end

  defp parse_included(%{"included" => included}) do
    included
    |> Map.new(fn %{"type" => type, "id" => id} = item ->
      {{type, id}, item} end)
  end
  defp parse_included(_) do
    %{}
  end
end
