defmodule LiveUI.Queries do
  @moduledoc """
  Default CRUD function, they can be overridden via `LiveUI` protocol.
  """

  import Ecto.Query

  def create(changeset, socket) do
    case LiveUI.Config.repo(changeset.data.__struct__) do
      PaperTrail -> PaperTrail.insert(changeset, originator: socket.assigns.current_user)
      repo -> repo.insert(changeset)
    end
  end

  def find_by_filter(params, flop, socket) do
    schema_module = socket.assigns.schema_module

    query =
      schema_module
      |> from(preload: ^socket.assigns.index_view[:preload])
      |> scope_to_owner(socket.assigns)

    Flop.run(query, update_relation_filters(params, flop, socket.assigns), for: schema_module)
  end

  defp scope_to_owner(query, assigns) do
    case LiveUI.ownership(struct(assigns.schema_module)) do
      {owner_key, assign_key} -> where(query, ^[{owner_key, assigns[assign_key].id}])
      _ -> query
    end
  end

  defp update_relation_filters(params, flop, assigns) do
    for field <- Keyword.keys(assigns.parent_relations),
        value = params[Atom.to_string(field)],
        value != nil && byte_size(value) > 0,
        reduce: flop do
      flop ->
        filters = Flop.Filter.put(flop.filters, %Flop.Filter{field: field, value: value})
        Map.put(flop, :filters, filters)
    end
  end

  def delete_ids(%{"selected" => selected}, socket) do
    from(record in socket.assigns.schema_module, where: record.id in ^selected)
    |> LiveUI.Config.repo().delete_all()
  end

  def find_by_id(%{"id" => id}, socket) do
    schema_module = socket.assigns.schema_module

    case LiveUI.ownership(struct(schema_module)) do
      {owner_key, assign_key} ->
        LiveUI.Config.repo().get_by(schema_module, [
          {:id, id},
          {owner_key, socket.assigns[assign_key].id}
        ])

      _ ->
        LiveUI.Config.repo().get(schema_module, id)
    end
  end

  def update(changeset, socket) do
    case LiveUI.Config.repo(changeset.data.__struct__) do
      PaperTrail -> PaperTrail.update(changeset, originator: socket.assigns.current_user)
      repo -> repo.update(changeset)
    end
  end

  def delete(record, _socket) do
    LiveUI.Config.repo().delete(record)
  end
end
