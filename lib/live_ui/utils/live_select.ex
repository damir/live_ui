defmodule LiveUI.Utils.LiveSelect do
  @moduledoc """
  LiveSelect utils.
  """

  import Ecto.Query

  def maybe_disabled(assigns, relation) do
    case scope_to_other_relations(assigns, struct(relation[:schema_module])) do
      [] -> false
      scopes -> Enum.find_value(scopes, fn {_key, value} -> value == 0 end)
    end
  end

  def options_finder(assigns, relation, text) do
    record = struct(relation[:schema_module])

    case LiveUI.search_function(record) do
      false ->
        from(m in relation[:schema_module],
          select:
            ^%{
              label: dynamic([m], field(m, ^relation[:search_field_for_title])),
              value: dynamic([m], m.id),
              description: dynamic([m], field(m, ^LiveUI.search_field_for_description(record)))
            },
          where: ilike(field(m, ^relation[:search_field_for_title]), ^"#{text}%"),
          where: ^scope_to_owner(assigns, record),
          where: ^scope_to_other_relations(assigns, record),
          limit: 5
        )
        |> LiveUI.Config.repo().all

      search_function ->
        search_function.(assigns, text)
    end
  end

  defp scope_to_owner(assigns, record) do
    case LiveUI.ownership(record) do
      {owner_key, assign_key} -> [{owner_key, assigns[assign_key].id}]
      _ -> []
    end
  end

  defp scope_to_other_relations(assigns, record) do
    relations_of_relation = LiveUI.parent_relations(record) || []

    for key <- Keyword.keys(relations_of_relation), assigns.parent_relations[key], reduce: [] do
      scope ->
        if assigns[:flop_meta] do
          scope_from_flop_filters(assigns.flop_meta.flop.filters, scope, key)
        else
          scope_from_params(assigns.form.params, scope, key)
        end
    end
  end

  defp scope_from_flop_filters(filters, scope, key) do
    Enum.find_value(filters, scope, fn filter ->
      Map.get(filter, key) && Map.get(filter, :value) &&
        Keyword.put(scope, key, Map.get(filter, :value))
    end)
  end

  # TODO: inline edit should use record instead params
  # ie. Map.get(assigns.form.data, key)
  defp scope_from_params(params, scope, key) do
    case params[Atom.to_string(key)] do
      nil -> Keyword.put(scope, key, 0)
      "" -> Keyword.put(scope, key, 0)
      value -> Keyword.put(scope, key, value)
    end
  end
end
