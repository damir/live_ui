defmodule LiveUI.Utils do
  @moduledoc """
  Utility functions.
  """

  def field_type(%module{}, field) do
    case module.__schema__(:type, field) do
      {:parameterized, Ecto.Enum, %{mappings: _mappings}} -> :enum
      {:array, _type} -> :array
      type -> type
    end
  end

  def image_field?(file_types) do
    length(~w(.jpg .jpeg .gif .png) -- file_types) < 4
  end

  def localized_time(time, format \\ :medium) do
    time |> Module.concat(LiveUI.Config.cldr(), DateTime).to_string(format: format) |> elem(1)
  end

  def localized_date(date, format \\ :medium) do
    date |> Module.concat(LiveUI.Config.cldr(), Date).to_string(format: format) |> elem(1)
  end
end
