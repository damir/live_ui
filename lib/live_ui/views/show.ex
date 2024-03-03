defmodule LiveUI.Views.Show do
  @moduledoc """
  Macro which defines `Show` live component.
  """

  defmacro __using__(opts) do
    config = LiveUI.Config.new(__CALLER__.module, Macro.expand(opts[:for], __CALLER__))

    quote location: :keep do
      use unquote(config.web_module), :live_view
      import LiveUI.Views.Show
      import LiveUI.Components.Core

      @config unquote(Macro.escape(config))
      for {config, value} <- @config, do: Module.put_attribute(__MODULE__, config, value)

      @impl true
      def mount(_params, _session, socket) do
        {:ok,
         socket
         |> assign(@config)
         |> assign(:editing_field, nil)
         |> assign(current_user: socket.assigns[:current_user])}
      end

      render()
      handle_params()
      handle_events()

      defoverridable mount: 3
      defoverridable render: 1
    end
  end

  defmacro render() do
    quote location: :keep do
      @impl true
      def render(var!(assigns)) do
        var!(assigns) = assign(var!(assigns), :config, @config)

        ~H"""
        <LiveUI.Components.Record.render
          {@config}
          page_title={@page_title}
          live_action={@live_action}
          record_path={@record_path}
          record={@record}
          editing_field={@editing_field}
          current_user={@current_user}
        />

        <.action_modal live_action={@live_action} action={:edit} return_to={@record_path}>
          <.p>Use this form to manage <%= @resource %> records in your database</.p>
          <.h3><%= "Edit #{@resource} record" %></.h3>

          <.live_component
            module={@form_module}
            id={@record.id}
            action={:edit}
            record={@record}
            resource={@resource}
            parent_relations={@parent_relations}
            title={@page_title}
            return_to={@record_path}
            current_user={@current_user}
            debug={@debug}
          />
        </.action_modal>

        <.action_modal live_action={@live_action} action={:delete} return_to={@record_path}>
          <.p>Deleting a <%= @resource %></.p>
          <.h3 class="mb-6">
            Are you sure you want to delete
            <.badge color="danger" size="xl" variant="outline" class="px-2" label={LiveUI.title(@record)} /> <%= @resource %>?
          </.h3>

          <.button link_type="live_patch" to={@record_path} variant="outline">
            Back
          </.button>

          <.link class="px-2 text-red-600" tabindex="-1" phx-click="delete">
            Delete
          </.link>
        </.action_modal>

        <.action_modal
          :for={custom_action <- Keyword.keys(@show_view[:actions]) -- [:edit, :delete]}
          action={custom_action}
          live_action={@live_action}
          return_to={@record_path}
        >
          <.live_component
            module={@show_view[:actions][custom_action][:component]}
            id={custom_action}
            action={custom_action}
            record={@record}
            index_path={@record_path}
            current_user={@current_user}
          />
        </.action_modal>
        """
      end
    end
  end

  defmacro handle_params() do
    quote location: :keep do
      @impl true
      def handle_params(%{"id" => id} = params, _, socket) do
        record = @show_view[:function].(params, socket)

        case record |> LiveUI.Config.repo().preload(@show_view[:preload]) do
          nil ->
            {:noreply,
             socket |> put_flash(:error, "Record not found.") |> push_navigate(to: @index_path)}

          record ->
            {:noreply,
             socket
             |> assign(:index_path, @index_path)
             |> assign(:record_path, "#{@index_path}/#{id}")
             |> assign(:page_title, page_title(socket, record))
             |> assign_new(:record, fn -> record end)}
        end
      end

      defp page_title(socket, record) do
        case socket.assigns.live_action do
          :show -> LiveUI.title(record)
          :edit -> "Edit #{@resource} record"
          :delete -> "Delete #{@resource} record"
          custom_action -> @show_view[:actions][custom_action][:name]
        end
      end
    end
  end

  defmacro handle_events() do
    quote location: :keep do
      @impl true
      def handle_event("delete", params, socket) do
        socket =
          try do
            {:ok, _} = @show_view[:actions][:delete][:function].(socket.assigns.record, socket)
            socket |> put_flash(:info, "#{String.capitalize(@resource)} deleted successfully.")
          rescue
            error in Ecto.ConstraintError -> socket |> put_flash(:error, inspect(error))
          end

        {:noreply, socket |> push_navigate(to: @index_path)}
      end

      @impl true
      def handle_event("edit-field", %{"field" => field}, socket),
        do: {:noreply, assign(socket, :editing_field, String.to_existing_atom(field))}

      @impl true
      def handle_event("edit-cancel", %{}, socket),
        do: {:noreply, assign(socket, :editing_field, nil)}

      @impl true
      def handle_info({:updated_record, record}, socket) do
        {:noreply,
         socket
         |> assign(record: record, editing_field: nil)
         |> put_flash(:info, "#{String.capitalize(@resource)} updated successfully.")}
      end
    end
  end
end
