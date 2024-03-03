defmodule LiveUI.Config.Flop do
  @moduledoc """
  Flop configuration.
  """

  def filters(record) do
    default_filters =
      for field <- Flop.Schema.filterable(record), do: {field, build_flop_filter(record, field)}

    filters_for_operators_by_index =
      for {{field, def}, index} <- Enum.with_index(default_filters),
          operator <- LiveUI.filter_operators(record)[field] || [] do
        {index,
         {field,
          [type: def[:type], op: operator, label: "#{Phoenix.Naming.humanize(field)} #{operator}"]}}
      end

    for {index, filter} <- filters_for_operators_by_index, reduce: default_filters do
      updated_default_filters ->
        List.insert_at(updated_default_filters, index + 1, filter)
    end
  end

  defp build_flop_filter(record, field) do
    case LiveUI.Utils.field_type(record, field) do
      :string -> [type: "text", op: :ilike]
      :enum -> [type: "select", options: enum_options_for_select(record, field)]
      :boolean -> [type: "select", options: [{"Yes", true}, {"No", false}]]
      :id -> relation_or_number_field(record, field)
      :integer -> [type: "number"]
      :naive_datetime -> [type: "datetime-local"]
      _ -> []
    end
  end

  defp enum_options_for_select(record, field) do
    for {k, v} <- Ecto.Enum.mappings(record.__struct__, field),
        do: {Phoenix.Naming.humanize(k), v}
  end

  defp relation_or_number_field(record, field) do
    if LiveUI.parent_relations(record)[field] do
      [type: "text", relation_field: field]
    else
      [type: "number"]
    end
  end

  # NOTE: lists are necesarry to merge other classes
  @table_css_opts [
    table_attrs: [class: "min-w-full table-auto"],
    thead_tr_attrs: [class: "text-gray-700 bg-gray-200 dark:bg-gray-700 dark:text-gray-300"],
    thead_th_attrs: [
      scope: "col",
      class: ["px-2 py-3 text-xs text-left font-medium tracking-wider uppercase"]
    ],
    tbody_tr_attrs: [
      class:
        "font-light text-left align-top text-gray-700 dark:text-gray-300 border-b border-gray-300 dark:border-gray-700 dark:bg-gray-800 last:border-0"
    ],
    tbody_td_attrs: [class: ["p-2"]]
  ]

  def table_css_opts(), do: Application.get_env(:live_ui, :flop_table_css_opts) || @table_css_opts
end
