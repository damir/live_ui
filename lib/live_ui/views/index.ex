defmodule LiveUI.Views.Index do
  @moduledoc """
  Macro which defines `Index` live component.
  """

  defmacro __using__(opts) do
    config = LiveUI.Config.new(__CALLER__.module, Macro.expand(opts[:for], __CALLER__))
    LiveUI.Views.Form.create_module(config)

    quote location: :keep do
      use unquote(config.web_module), :live_view
      import LiveUI.Views.Index
      import LiveUI.Components.Core

      @config unquote(Macro.escape(config))
      for {config, value} <- @config, do: Module.put_attribute(__MODULE__, config, value)

      @impl true
      def mount(_params, _session, socket) do
        {:ok,
         socket
         |> assign(@config)
         |> assign(:record, struct(@schema_module))
         |> assign(current_user: socket.assigns[:current_user])
         |> assign(:searching, false)
         |> assign(:selecting, false)
         |> assign(:selected, [])
         |> assign(:all_ids, [])
         |> stream_configure(:items, dom_id: &"#{@resources}-#{&1.id}")
         |> stream(:items, [])}
      end

      render()
      handle_params()
      handle_selected_records()
      handle_events_from_search_form()
      handle_event_from_live_select()

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
        <LiveUI.Components.Table.render
          {@config}
          page_title={@page_title}
          flop_meta={@flop_meta}
          flop_filters={@flop_filters}
          record={@record}
          live_action={@live_action}
          streams={@streams}
          searching={@searching}
          selecting={@selecting}
          selected={@selected}
        />

        <.action_modal live_action={@live_action} action={:new} return_to={@index_path}>
          <.p>Use this form to manage <%= @resource %> records in your database</.p>
          <.h3><%= "Create #{@resource} record" %></.h3>

          <.live_component
            module={@form_module}
            id={:new}
            action={:new}
            record={@record}
            resource={@resource}
            parent_relations={@parent_relations}
            title={@page_title}
            return_to={@index_path}
            current_user={@current_user}
            debug={@debug}
          />
        </.action_modal>

        <.action_modal
          :if={length(@selected) > 0}
          live_action={@live_action}
          action={:delete}
          return_to={@index_path}
        >
          <.p>Deleting multiple <%= @resources %></.p>
          <.h3 class="mb-6">
            Are you sure you want to permanently delete <%= length(@selected) %> <%= if(
              length(@selected) == 1,
              do: @resource,
              else: @resources
            ) %>?
          </.h3>

          <.button link_type="live_patch" to={@index_path} variant="outline">
            Back
          </.button>

          <.link
            class="px-2 text-red-600"
            tabindex="-1"
            phx-click={JS.push("delete", value: %{selected: @selected})}
          >
            Delete
          </.link>
        </.action_modal>

        <.action_modal
          :for={custom_action <- Keyword.keys(@index_view[:actions]) -- [:new]}
          action={custom_action}
          live_action={@live_action}
          return_to={@index_path}
        >
          <.live_component
            module={@index_view[:actions][custom_action][:component]}
            id={custom_action}
            action={custom_action}
            index_path={@index_path}
            current_user={@current_user}
          />
        </.action_modal>

        <.action_modal
          :for={custom_action <- Keyword.keys(@index_view[:batch_actions]) -- [:delete]}
          :if={length(@selected) > 0}
          action={custom_action}
          live_action={@live_action}
          return_to={@index_path}
        >
          <.live_component
            module={@index_view[:batch_actions][custom_action][:component]}
            id={custom_action}
            action={custom_action}
            index_path={@index_path}
            current_user={@current_user}
            selected={@selected}
          />
        </.action_modal>
        """
      end
    end
  end

  # TODO: sanitize field inputs for Flop.validate
  defmacro handle_params() do
    quote location: :keep do
      @impl true
      def handle_params(params, _, socket) do
        socket =
          case Flop.validate(params, for: @schema_module) do
            {:ok, flop} ->
              {items, flop_meta} = @index_view[:function].(params, flop, socket)
              socket |> assign(flop_meta: flop_meta) |> stream(:items, items, reset: true)

            _ ->
              push_navigate(socket, to: @index_path)
          end

        {:noreply, socket |> assign(:page_title, page_title(socket))}
      end

      defp page_title(socket) do
        case socket.assigns.live_action do
          :index ->
            String.capitalize(@resources)

          :new ->
            "New #{@resource}"

          :delete ->
            "Delete #{@resources}"

          custom_action ->
            (@index_view[:actions] ++ @index_view[:batch_actions])[custom_action][:name]
        end
      end
    end
  end

  defmacro handle_selected_records() do
    quote location: :keep do
      def handle_event("selecting", params, socket) do
        # reset stream to re-render rows with select logic
        {items, _flop_meta} =
          @index_view[:function].(params, socket.assigns.flop_meta.flop, socket)

        {:noreply,
         socket
         |> assign(:selecting, not socket.assigns.selecting)
         |> assign(:selected, [])
         |> assign(:all_ids, Enum.map(items, & &1.id))
         |> stream(:items, items, reset: true)}
      end

      def handle_event("select-record", %{"id" => id}, socket) do
        selected =
          if id in socket.assigns.selected do
            List.delete(socket.assigns.selected, id)
          else
            [id | socket.assigns.selected]
          end

        {:noreply, socket |> assign(selected: selected)}
      end

      def handle_event("select-all", _, socket) do
        {:noreply, socket |> assign(selected: socket.assigns.all_ids)}
      end

      def handle_event("select-none", _, socket) do
        {:noreply, socket |> assign(selected: [])}
      end

      def handle_event(_, %{"selected" => []}, socket) do
        {:noreply,
         socket
         |> put_flash(:error, "No record is selected.")
         |> push_navigate(to: socket.assigns.index_path)}
      end

      def handle_event("delete", %{"selected" => selected} = params, socket) do
        socket =
          try do
            @index_view[:batch_actions][:delete][:function].(params, socket)

            socket
            |> put_flash(
              :info,
              "#{Phoenix.Naming.humanize(@resources)} (#{length(selected)}) are deleted successfully."
            )
          rescue
            error in Postgrex.Error -> socket |> put_flash(:error, inspect(error))
          end

        {:noreply, socket |> push_navigate(to: socket.assigns.index_path)}
      end
    end
  end

  defmacro handle_events_from_search_form() do
    quote location: :keep do
      def handle_event("searching", params, socket),
        do: {:noreply, socket |> assign(:searching, !socket.assigns.searching)}

      @impl true
      def handle_event("#{@resources}-update-filter", params, socket),
        do:
          {:noreply, push_patch(socket, to: unverified_path(socket, Router, @index_path, params))}

      @impl true
      def handle_event("#{@resources}-reset-filter", _, %{assigns: assigns} = socket) do
        flop = assigns.flop_meta.flop |> Flop.set_page(1) |> Flop.reset_filters()

        socket =
          push_patch(socket,
            to: Flop.Phoenix.build_path(@index_path, flop, backend: assigns.flop_meta.backend)
          )

        {:noreply, socket}
      end
    end
  end

  defmacro handle_event_from_live_select() do
    quote location: :keep do
      for {field, relation} <- @parent_relations do
        @relation_field "flop_#{field}"
        @relation relation

        @impl true
        def handle_event(
              "live_select_change",
              %{"field" => @relation_field, "text" => text, "id" => id},
              socket
            ) do
          options = LiveUI.Utils.LiveSelect.options_finder(socket.assigns, @relation, text)
          send_update(LiveSelect.Component, id: id, options: options)
          {:noreply, socket}
        end
      end
    end
  end
end
