defmodule LiveUI.Components.Form do
  @moduledoc """
  Form to create/update records.
  """

  use Phoenix.Component
  import LiveUI.Components.Core
  import Phoenix.Naming

  attr :form, :map
  attr :action, :atom
  attr :uploads, :any, default: false
  attr :resource, :string
  attr :parent_relations, :any
  attr :myself, :string
  attr :return_to, :string
  attr :debug, :boolean

  def render(assigns) do
    view_config =
      if assigns.action == :new,
        do: LiveUI.index_view(assigns.form.data),
        else: LiveUI.show_view(assigns.form.data)

    assigns = assign(assigns, :view_config, view_config)

    ~H"""
    <.form
      for={@form}
      id={"#{@resource}-form"}
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save"
    >
      <.field_input
        :for={field <- @view_config[:actions][@action][:fields]}
        form={@form}
        action={@action}
        view_config={@view_config}
        field={field}
        uploads={@uploads}
        resource={@resource}
        myself={@myself}
      />

      <.button phx-disable-with="Saving...">Save <%= @resource %></.button>
      <.link patch={@return_to} class="px-2">Back</.link>
    </.form>

    <LiveUI.Components.Inspector.render
      :if={@debug}
      name={"Form assigns #{inspect(self())}"}
      term={assigns}
      id={"#{@resource}-form"}
      class="pt-8"
    />
    """
  end

  attr :form, :map
  attr :field, :string
  attr :debounce, :integer, default: 200
  attr :action, :atom
  attr :view_config, :list
  attr :resource, :string
  attr :uploads, :any, default: false
  attr :myself, :string

  # for inline form
  attr :inline, :boolean, default: false
  attr :wrapper_class, :string, default: nil
  attr :label_class, :string, default: nil

  def field_input(assigns) do
    assigns =
      if assigns.inline do
        assigns |> assign(:wrapper_class, "my-0") |> assign(:label_class, "hidden")
      else
        assigns
      end

    ~H"""
    <%= case LiveUI.Utils.field_type(@form.data, @field) do %>
      <% :string -> %>
        <%= if LiveUI.uploads(@form.data)[@field] do %>
          <.upload_input field={@field} form={@form} uploads={@uploads} target={@myself} />
        <% else %>
          <.field
            field={@form[@field]}
            type={@view_config[:actions][@action][:inputs][@field] || "text"}
            autocomplete="off"
            label_class={@label_class}
            wrapper_class={@wrapper_class}
            help_text={LiveUI.input_hints(@form.data)[@field]}
            phx-debounce={@debounce}
          />
        <% end %>
      <% :enum -> %>
        <.field
          field={@form[@field]}
          type="select"
          label_class={@label_class}
          wrapper_class={@wrapper_class}
          prompt="--select--"
          options={enum_options(@view_config, @form, @field)}
          help_text={LiveUI.input_hints(@form.data)[@field]}
          phx-debounce={@debounce}
        />
      <% :boolean -> %>
        <.field
          field={@form[@field]}
          type="checkbox"
          wrapper_class={if @wrapper_class, do: [@wrapper_class, "flex items-center"]}
          help_text={LiveUI.input_hints(@form.data)[@field]}
          phx-debounce={@debounce}
        />
      <% :integer -> %>
        <.field
          field={@form[@field]}
          type="number"
          autocomplete="off"
          label_class={@label_class}
          wrapper_class={@wrapper_class}
          help_text={LiveUI.input_hints(@form.data)[@field]}
          phx-debounce={@debounce}
        />
      <% :id -> %>
        <.relation_input
          myself={@myself}
          form={@form}
          field={@field}
          resource={@resource}
          inline={@inline}
          debounce={@debounce}
        />
      <% :naive_datetime -> %>
        <.field
          field={@form[@field]}
          type="datetime-local"
          label_class={@label_class}
          wrapper_class={@wrapper_class}
          help_text={LiveUI.input_hints(@form.data)[@field]}
          phx-debounce={@debounce}
        />
      <% type -> %>
        <%= if type in [:map, :array] do %>
          <%= if LiveUI.uploads(@form.data)[@field] do %>
            <.upload_input field={@field} form={@form} uploads={@uploads} target={@myself} />
          <% else %>
            <.field
              field={@form[@field]}
              type="textarea"
              label_class={@label_class}
              wrapper_class={@wrapper_class}
              help_text={LiveUI.input_hints(@form.data)[@field]}
              value={Map.get(@form.data, @field) |> Jason.encode!(pretty: true)}
              phx-debounce={@debounce}
            />
          <% end %>
        <% end %>
    <% end %>
    """
  end

  defp enum_options(view_config, form, field) do
    formatter = view_config[:formatters][field] || (&humanize/1)

    Enum.map(Ecto.Enum.values(form.data.__struct__, field), fn value ->
      {value |> Atom.to_string() |> formatter.(), value}
    end)
  end

  attr :form, :map
  attr :field, :atom
  attr :debounce, :integer
  attr :inline, :boolean, default: false
  attr :resource, :string
  attr :myself, :string

  def relation_input(assigns) do
    assigns = assigns |> assign(parent_relations: LiveUI.parent_relations(assigns.form.data))
    relation = Keyword.get(assigns.parent_relations, assigns.field)

    live_select_value =
      if Map.get(assigns.form.data, assigns.field) do
        relation_heading = assigns.form.data |> Map.get(relation[:name]) |> LiveUI.title()

        if relation_heading == assigns.form.params["#{assigns.field}_text_input"],
          do: [value: {relation_heading, Map.get(assigns.form.data, assigns.field)}]
      end

    assigns =
      assigns
      |> assign(
        relation: relation,
        live_select_value: live_select_value || [],
        live_select_disabled: LiveUI.Utils.LiveSelect.maybe_disabled(assigns, relation)
      )

    ~H"""
    <div
      phx-feedback-for={"#{@resource}[#{@field}]"}
      class={[
        "pc-form-field-wrapper",
        if(@inline, do: "my-0"),
        @form[@field].errors != [] && "mb-5 pc-form-field-wrapper--error"
      ]}
    >
      <.field_label :if={!@inline} for={"#{@resource}_#{@field}"}>
        <%= humanize(@relation[:name]) %>
      </.field_label>

      <LiveSelect.live_select
        id={"ls-#{@field}-inline-#{@inline}"}
        field={@form[@field]}
        {@live_select_value}
        update_min_len={1}
        debounce={@debounce}
        mode={:single}
        placeholder={"Search by #{@relation[:search_field_for_title]}"}
        phx-target={@myself}
        allow_clear
        disabled={@live_select_disabled}
        {LiveUI.Config.LiveSelect.css_opts()}
      >
        <:option :let={option}>
          <div><%= option.label %></div>
          <div class="pb-1 text-xs"><%= option.description %></div>
        </:option>
      </LiveSelect.live_select>

      <p
        :for={msg <- Enum.map(@form[@field].errors, &translate_error(&1))}
        class={["pc-form-field-error", if(@inline, do: "-mb-5")]}
      >
        <%= msg %>
      </p>
    </div>
    """
  end

  def upload_input(assigns) do
    ~H"""
    <div class="mb-4">
      <.field_label>
        <%= humanize(@field) %>
      </.field_label>

      <div
        class="p-4 mb-2 border-2 rounded border-dashed border-gray-600"
        phx-drop-target={@uploads[@field].ref}
      >
        <.p class="text-lg font-semibold">
          Drop
          <%= if @uploads[@field].max_entries > 1 do %>
            up to <%= @uploads[@field].max_entries %> files
          <% else %>
            file
          <% end %>
          here or
        </.p>
        <.p><.live_file_input upload={@uploads[@field]} /></.p>

        <.ul>
          <li>
            Max size:
            <.badge
              label={"#{(@uploads[@field].max_file_size / 1_000_000) |> Float.round(2)} MB"}
              color="gray"
              variant="outline"
              class="px-1"
            />
          </li>
          <li>
            Accepted formats:
            <.badge
              :for={item <- LiveUI.uploads(@form.data)[@field][:accept]}
              label={item}
              color="gray"
              variant="outline"
              class="p-1 mr-1"
            />
          </li>
        </.ul>
      </div>

      <.alert
        :for={error <- upload_errors(@uploads[@field])}
        color="danger"
        label={humanize(error)}
        class="mt-4"
      />

      <div :for={{entry, index} <- Enum.with_index(@uploads[@field].entries)} class="flex">
        <div :if={image?(entry.client_type)} class="pt-4 w-1/2 justify-left">
          <.live_img_preview
            entry={entry}
            class="object-scale-down max-h-full drop-shadow rounded-md"
          />
        </div>

        <div class={if image?(entry.client_type), do: "p-4", else: "py-4"}>
          <div class="flex flex-wrap items-baseline gap-2">
            <.badge color="gray" variant="outline" size="lg" label={"##{index + 1}"} />
            <.p class="font-medium"><%= entry.client_name %></.p>
            <.p
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              phx-value-field={@field}
              phx-target={@target}
            >
              <.icon name="hero-trash" class="cursor-pointer text-sky-600" />
            </.p>
          </div>

          <.ul class="my-2">
            <li>Type: <%= entry.client_type %></li>
            <li>Size: <%= (entry.client_size / 1_000_000) |> Float.round(2) %> MB</li>
            <li>Modified: <%= localized_timestamp(entry.client_last_modified) %></li>
          </.ul>

          <.progress
            :if={Enum.empty?(upload_errors(@uploads[@field], entry))}
            color="info"
            size="xl"
            value={entry.progress}
            max={100}
            label={"#{entry.progress}%"}
            class="max-w-full"
          />

          <.alert
            :for={error <- upload_errors(@uploads[@field], entry)}
            with_icon
            color="danger"
            label={humanize(error)}
          />
        </div>
      </div>
    </div>
    """
  end

  defp image?(file_type) do
    (file_type |> String.split("/") |> List.last()) in ~w(jpg jpeg gif png)
  end

  defp localized_timestamp(timestamp),
    do:
      (timestamp / 1000) |> trunc |> DateTime.from_unix!() |> LiveUI.Utils.localized_time(:short)

  defp translate_error({msg, opts}) do
    case LiveUI.Config.error_translator_function() do
      {module, function} -> apply(module, function, [{msg, opts}])
      nil -> "invalid value"
    end
  end
end
