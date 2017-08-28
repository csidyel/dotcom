defmodule Content.Project do
  @moduledoc """
  Represents the Project content type in the CMS.
  """

  import Content.Helpers, only: [
    field_value: 2,
    int_or_string_to_int: 1,
    parse_body: 1,
    parse_date: 2,
    parse_files: 2,
    parse_image: 2,
    parse_images: 2
  ]

  @enforce_keys [:id]
  defstruct [
    :id,
    body: Phoenix.HTML.raw(""),
    contact_information: "",
    end_year: "",
    featured: false,
    featured_image: %Content.Field.Image{},
    files: [],
    media_email: "",
    media_phone: "",
    photo_gallery: [],
    posted_on: "",
    start_year: "",
    status: "",
    teaser: "",
    title: "",
    updated_on: nil
  ]

  @type t :: %__MODULE__{
    id: integer,
    body: Phoenix.HTML.safe,
    contact_information: String.t,
    end_year: String.t | nil,
    featured: boolean,
    featured_image: Content.Field.Image.t | nil,
    files: [Content.Field.File.t] | [],
    media_email: String.t,
    media_phone: String.t,
    photo_gallery: [Content.Field.Image.t] | [],
    start_year: String.t,
    status: String.t,
    teaser: String.t,
    title: String.t,
    updated_on: Date.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      id: int_or_string_to_int(field_value(data, "nid")),
      body: parse_body(data),
      contact_information: field_value(data, "field_contact_information"),
      end_year: field_value(data, "field_end_year"),
      featured: field_value(data, "field_featured"),
      featured_image: parse_image(data, "field_featured_image"),
      files: parse_files(data, "field_files"),
      media_email: field_value(data, "field_media_email"),
      media_phone: field_value(data, "field_media_phone"),
      photo_gallery: parse_images(data, "field_photo_gallery"),
      start_year: field_value(data, "field_start_year"),
      status: field_value(data, "field_project_status"),
      teaser: field_value(data, "field_teaser"),
      title: field_value(data, "title"),
      updated_on: parse_date(data, "field_updated_on")
    }
  end
end
