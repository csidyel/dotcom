defmodule Algolia.Config do
  require Logger

  defstruct [:app_id, :admin, :search]

  @type t :: %__MODULE__{
          app_id: String.t() | nil,
          admin: String.t() | nil,
          search: String.t() | nil
        }

  @spec config :: t
  def config do
    :algolia
    |> Application.get_env(:config)
    |> Enum.reduce([], &parse_config/2)
    |> __MODULE__.__struct__()
  end

  defp parse_config({_key, "$" <> _}, config) do
    config
  end

  defp parse_config({key, {:system, system_key}}, config) do
    Keyword.put(config, key, System.get_env(system_key))
  end

  defp parse_config({key, val}, config) do
    Keyword.put(config, key, val)
  end
end
