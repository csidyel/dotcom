defmodule Site.Validation do
  @moduledoc """
  Helper functions for performing data validation.
  """

  @doc """
  Takes a list of functions and a map of parameters.
  Returns a list containing the names of fields where validation errors occurred.
  Expects validation functions to return :ok or String.t
  """
  @spec validate([(map -> String.t() | :ok)], map) :: [String.t()]
  def validate(validators, params) do
    validators
    |> Enum.reduce(MapSet.new(), &add_errors_to_mapset(&1, &2, params))
    |> MapSet.to_list()
  end

  @spec add_errors_to_mapset((map -> String.t() | :ok), MapSet.t(String.t()), map) ::
          MapSet.t(String.t())
  defp add_errors_to_mapset(validator_fn, errors_map_set, params) do
    params
    |> validator_fn.()
    |> do_add_errors_to_mapset(errors_map_set)
  end

  @spec do_add_errors_to_mapset(:ok | String.t(), MapSet.t(String.t())) :: MapSet.t(String.t())
  defp do_add_errors_to_mapset(:ok, errors) do
    errors
  end

  defp do_add_errors_to_mapset(error, errors) do
    MapSet.put(errors, error)
  end

  @doc """
  Takes a map with string keys of field names associates to a validation function.
  Returns a map containing the field names associated to field errors, or and empty map.
  Expects validation functions to return :ok or String.t
  """
  @spec validate_by_field(map, map) :: map
  def validate_by_field(validations, params) do
    validations
    |> Enum.reduce(%{}, fn {field, validator}, errors_map ->
      error = validator.(params)

      case {error, is_binary(error)} do
        {:ok, _} -> errors_map
        {_, true} -> Map.merge(errors_map, %{field => error})
        {_, _} -> Map.merge(errors_map, %{field => "error"})
      end
    end)
  end
end
