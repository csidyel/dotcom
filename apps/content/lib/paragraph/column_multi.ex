defmodule Content.Paragraph.ColumnMulti do
  @moduledoc """
  A set of columns to organize layout on the page.
  """
  alias Content.Paragraph.{Column, ColumnMultiHeader}

  defstruct [
    header: nil,
    columns: []
  ]

  @type t :: %__MODULE__{
    header: ColumnMultiHeader.t,
    columns: [Column.t]
  }

  @spec from_api(map) :: t
  def from_api(data) do
    header =
      data
      |> Map.get("field_multi_column_header", [])
      |> Enum.map(&ColumnMultiHeader.from_api/1)
      # There is only ever 1 header element
      |> List.first()

    columns =
      data
      |> Map.get("field_column", [])
      |> Enum.map(&Column.from_api/1)

    %__MODULE__{
      header: header,
      columns: columns
    }
  end

end
