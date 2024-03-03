defmodule LiveUI.Changeset do
  @moduledoc """
  Changeset functions for create and update.
  """

  import Ecto.Changeset

  def create_changeset(record, params, socket),
    do: changeset_for_action(LiveUI.index_view(record)[:actions][:new], record, params, socket)

  def update_changeset(record, params, socket),
    do: changeset_for_action(LiveUI.show_view(record)[:actions][:edit], record, params, socket)

  defp changeset_for_action(action_config, record, params, socket) do
    upload_fields = record |> LiveUI.uploads() |> Keyword.keys()
    ownership = LiveUI.ownership(record)

    ownership_field =
      case ownership do
        {ownership_field, _} -> [ownership_field]
        _ -> []
      end

    changeset =
      record
      |> cast(decoded_params(params, record), action_config[:fields] -- ownership_field)
      # ownership and upload fields are processed separately
      |> validate_required(
        (action_config[:fields] -- action_config[:optional_fields]) --
          (ownership_field ++ upload_fields)
      )

    # ownership = {:user_id, :current_user}
    case ownership do
      {ownership_field, assign_field} ->
        put_change(changeset, ownership_field, Map.get(socket.assigns[assign_field] || %{}, :id))

      _ ->
        changeset
    end
  end

  defp decoded_params(params, record) do
    array_or_map_fields =
      (LiveUI.fields_by_type(record)[:array] |> List.wrap()) ++
        (LiveUI.fields_by_type(record)[:map] |> List.wrap())

    for field <- array_or_map_fields, reduce: params do
      params ->
        field = Atom.to_string(field)

        with true <- is_binary(params[field]),
             {:ok, decoded_value} <- Jason.decode(params[field]) do
          Map.put(params, field, decoded_value)
        else
          _ -> params
        end
    end
  end
end
