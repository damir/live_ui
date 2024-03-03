defmodule LiveUI.Components.EditableField do
  @moduledoc """
  Form input for inline editing.
  """

  use Phoenix.LiveComponent
  alias LiveUI.Views.Form
  import LiveUI.Components.Core

  def render(assigns) do
    ~H"""
    <div>
      <.focus_wrap
        id={"#{@field}-edit-focus-wrap"}
        phx-click-away="edit-cancel"
        phx-window-keydown="edit-cancel"
        phx-key="escape"
      >
        <.form
          id={"#{@field}-edit"}
          name={@field}
          for={@form}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <div class="flex flex-wrap items-top gap-2">
            <LiveUI.Components.Form.field_input
              myself={@myself}
              form={@form}
              action={:edit}
              field={@field}
              view_config={@view_config}
              resource={LiveUI.resource(@record)}
              inline={true}
            />

            <.button phx-disable-with="Saving..." variant="outline" class="h-[38px]">Save</.button>
            <.alert
              :if={!Enum.empty?(@form.errors) && !@form.errors[@field]}
              color="danger"
              label={inspect(@form.errors, pretty: true)}
            />
          </div>
        </.form>
      </.focus_wrap>
    </div>
    """
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns) |> assign(view_config: LiveUI.show_view(assigns.record))
    {:ok, assign(socket, form: to_form(get_changeset(socket, %{})))}
  end

  def handle_event("validate", params, socket) do
    changeset = socket |> get_changeset(params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", params, socket) do
    changeset = get_changeset(socket, params)

    case Form.save_record(changeset, socket) do
      {:ok, record} ->
        record =
          if relation = socket.assigns.relation do
            record
            |> Ecto.reset_fields([relation[:name]])
            |> LiveUI.Config.repo().preload(relation[:name])
          else
            record
          end

        send(self(), {:updated_record, record})
        {:noreply, assign(socket, :edit, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = put_flash(socket, :error, "ouch")
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options =
      LiveUI.Utils.LiveSelect.options_finder(socket.assigns, socket.assigns.relation, text)

    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end

  defp get_changeset(socket, params) do
    record = socket.assigns.record
    params = params[LiveUI.resource(record)]

    params =
      case socket.assigns.relation do
        nil -> params || %{}
        relation -> params || Form.parent_relation_param(record, relation)
      end

    update_changeset_fun = socket.assigns.view_config[:actions][:edit][:changeset]
    update_changeset_fun.(record, params, socket)
  end
end
