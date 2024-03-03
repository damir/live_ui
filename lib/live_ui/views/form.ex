defmodule LiveUI.Views.Form do
  @moduledoc """
  Macro which creates form live component to create and update a records.
  """

  def create_module(config) do
    content =
      quote do
        import LiveUI.Views.Form
        module_content(unquote(config))
      end

    Module.create(config.form_module, content, Macro.Env.location(__ENV__))
  end

  defmacro module_content(config) do
    quote location: :keep do
      use unquote(config.web_module), :live_component
      alias LiveUI.Components.Form
      import Ecto.Changeset
      import LiveSelect

      for {config, value} <- unquote(Macro.escape(config)),
          do: Module.put_attribute(__MODULE__, config, value)

      record = @schema_module |> struct()
      @create_changeset_fun @index_view[:actions][:new][:changeset]
      @update_changeset_fun @show_view[:actions][:edit][:changeset]
      @validate_changeset_on_create_fun @index_view[:actions][:new][:validate_changeset]
      @validate_changeset_on_update_fun @show_view[:actions][:edit][:validate_changeset]

      @impl true
      def render(var!(assigns)) do
        # uploads is reserved assign by LiveView, it cannot be set in mount
        var!(assigns) =
          if var!(assigns)[:uploads] do
            var!(assigns)
          else
            assign(var!(assigns), uploads: false)
          end

        ~H"""
        <div>
          <Form.render
            myself={@myself}
            form={@form}
            action={@action}
            resource={@resource}
            parent_relations={@parent_relations}
            return_to={@return_to}
            debug={@debug}
            uploads={@uploads}
          />
        </div>
        """
      end

      @impl true
      def update(assigns, socket) do
        params =
          for {_, relation} <- assigns.parent_relations, assigns.action != :new, reduce: %{} do
            params -> Map.merge(params, parent_relation_param(assigns.record, relation))
          end

        changeset_fun =
          if assigns.action == :new,
            do: @validate_changeset_on_create_fun,
            else: @validate_changeset_on_update_fun

        changeset = changeset_fun.(assigns.record, params, socket)

        {:ok, socket |> assign(assigns) |> assign_uploads() |> assign(:form, to_form(changeset))}
      end

      handle_events_for_uploads()
      process_uploads()
      handle_events_for_validate()
      handle_events_for_save()
      handle_events_for_live_select(unquote(config.parent_relations), unquote(config.resource))

      # helpers
      defp form_fields_for_action(live_action) do
        @index_view[:actions][live_action][:fields] || @show_view[:actions][live_action][:fields]
      end
    end
  end

  # param for live_select input
  def parent_relation_param(record, relation) do
    parent_record = Map.get(record, relation[:name])
    text = (parent_record || %{}) |> Map.get(relation[:search_field_for_title])
    %{"#{relation[:owner_key]}_text_input" => text}
  end

  defmacro handle_events_for_uploads() do
    quote location: :keep do
      if Enum.empty?(@uploads_opts) do
        def assign_uploads(socket), do: socket
      else
        def assign_uploads(socket) do
          for {upload_field, config} <- @uploads_opts,
              upload_field in form_fields_for_action(socket.assigns.action),
              reduce: socket do
            socket ->
              socket
              |> allow_upload(upload_field,
                accept: config[:accept],
                max_entries: config[:max_entries] || 1,
                max_file_size: config[:max_file_size]
              )
          end
        end
      end

      for {upload_field, _upload_config} <- @schema_module |> struct() |> LiveUI.uploads() do
        @upload_field upload_field
        @upload_field_to_s Atom.to_string(upload_field)
        def handle_event("cancel-upload", %{"ref" => ref, "field" => @upload_field_to_s}, socket) do
          {:noreply, cancel_upload(socket, @upload_field, ref)}
        end
      end
    end
  end

  defmacro process_uploads() do
    quote location: :keep do
      defp process_uploads(socket, params, changeset) when changeset.valid? do
        for upload_field <- Keyword.keys(@uploads_opts),
            upload_field in form_fields_for_action(socket.assigns.action),
            reduce: params do
          params ->
            upload_field_to_s = Atom.to_string(upload_field)

            url_paths =
              consume_uploaded_entries(socket, upload_field, fn meta, entry ->
                file_type = entry.client_name |> String.split(".") |> List.last()
                file_name = "#{entry.uuid}.#{file_type}"

                file_path =
                  Path.join(["priv", "static", "uploads", @resource, upload_field_to_s, file_name])

                File.mkdir_p!(Path.dirname(file_path))
                File.cp!(meta.path, file_path)

                url_path =
                  static_path(socket, "/uploads/#{@resource}/#{upload_field}/#{file_name}")

                {:ok, url_path}
              end)

            if length(url_paths) > 0 do
              url_paths =
                case LiveUI.Utils.field_type(@schema_module |> struct(), upload_field) do
                  :string -> List.first(url_paths)
                  :array -> url_paths
                  _ -> {:error, :invalid_field_type}
                end

              Map.put(params, upload_field_to_s, url_paths)
            else
              params
            end
        end
      end

      defp process_uploads(_socket, params, _changeset), do: params
    end
  end

  defmacro handle_events_for_validate() do
    quote location: :keep do
      @impl true
      def handle_event("validate", params, socket),
        do: validate(socket, socket.assigns.action, params[@resource])

      defp validate(socket, :new, params) do
        changeset = @validate_changeset_on_create_fun.(socket.assigns.record, params, socket)
        {:noreply, assign(socket, :form, to_form(changeset |> Map.put(:action, :validate)))}
      end

      defp validate(socket, :edit, params) do
        changeset = @validate_changeset_on_update_fun.(socket.assigns.record, params, socket)
        {:noreply, assign(socket, :form, to_form(changeset |> Map.put(:action, :validate)))}
      end

      defp validate(socket, action, _params),
        do: {:noreply, put_flash(socket, :error, "Validation changeset not found for #{action}.")}
    end
  end

  defmacro handle_events_for_save() do
    quote location: :keep do
      @impl true
      def handle_event("save", params, socket),
        do: save(socket, socket.assigns.action, params[@resource], String.to_atom(@resource))

      construct_create_record()
      construct_update_record()

      defp save(socket, action, _params, _resource),
        do: {:noreply, put_flash(socket, :error, "Save changeset not found for #{action}.")}
    end
  end

  defmacro construct_create_record() do
    quote location: :keep do
      defp save(socket, :new, params, resource) do
        # NOTE: can we process uploads without repeating changeset call?
        changeset = @create_changeset_fun.(struct(@schema_module), params, socket)
        params = process_uploads(socket, params, changeset)
        changeset = @create_changeset_fun.(struct(@schema_module), params, socket)

        case save_record(changeset, socket) do
          {:ok, _record} ->
            {:noreply,
             socket
             |> put_flash(:info, "#{Phoenix.Naming.humanize(resource)} created successfully.")
             |> push_navigate(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
      end
    end
  end

  defmacro construct_update_record() do
    quote location: :keep do
      defp save(socket, :edit, params, resource) do
        # NOTE: is there a way to process uploads without repeating changeset call?
        changeset = @create_changeset_fun.(socket.assigns.record, params, socket)
        params = process_uploads(socket, params, changeset)
        changeset = @create_changeset_fun.(socket.assigns.record, params, socket)

        case save_record(changeset, socket) do
          {:ok, _record} ->
            {:noreply,
             socket
             |> put_flash(:info, "#{Phoenix.Naming.humanize(resource)} updated successfully.")
             |> push_navigate(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
      end
    end
  end

  defmacro handle_events_for_live_select(parent_relations, resource) do
    quote location: :keep do
      for {field, relation} <- unquote(parent_relations) do
        @relation relation
        @name relation[:name]
        @relation_field "#{unquote(resource)}_#{field}"

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

  def save_record(%{data: data} = changeset, socket) do
    result =
      case data.__meta__.state do
        :built -> LiveUI.index_view(data)[:actions][:new][:function].(changeset, socket)
        :loaded -> LiveUI.show_view(data)[:actions][:edit][:function].(changeset, socket)
      end

    case result do
      {:ok, %{model: record, version: _}} -> {:ok, record}
      {:ok, record} -> {:ok, record}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
