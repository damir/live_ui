defmodule LiveUI.Components.Record do
  @moduledoc """
  Show a record.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias LiveUI.Components.Field

  import Phoenix.Naming
  import LiveUI.Components.Core
  import LiveUI.Utils

  # naming
  attr :resource, :string
  attr :resources, :string

  # paths
  attr :namespace, :string
  attr :record_path, :string
  attr :index_path, :string

  # data
  attr :parent_relations, :list
  attr :page_title, :string
  attr :current_user, :map

  # config
  attr :actions, :list
  attr :live_action, :atom
  attr :debug, :list

  # form
  attr :form_module, :atom
  attr :record, :any
  attr :editing_field, :atom

  def render(assigns) do
    assigns = assign(assigns, :heading, LiveUI.heading(assigns.record))

    ~H"""
    <.p :if={LiveUI.description(@record)}><%= LiveUI.description(@record) %></.p>

    <div class="flex flex-wrap items-center justify-between gap-4">
      <%= if @heading do %>
        <%= @heading %>
      <% else %>
        <.h3><%= LiveUI.title(@record) %></.h3>
      <% end %>

      <div class="flex flex-wrap items-center gap-2">
        <.link patch={"#{@record_path}/delete"} phx-click={JS.push_focus()}>
          <%= @show_view[:actions][:delete][:name] %>
        </.link>

        <.action_button
          :for={custom_action <- Keyword.keys(@show_view[:actions]) -- [:delete]}
          config={@show_view[:actions][custom_action]}
          action={custom_action}
          url_path={@record_path}
        >
          <%= @show_view[:actions][custom_action][:name] %>
        </.action_button>
      </div>
    </div>

    <div class="flex flex-wrap items-center gap-4">
      <.relation_heading
        :for={{field, relation} <- @parent_relations}
        :if={field in @show_view[:fields]}
        field={relation[:name]}
        record={Map.get(@record, relation[:name])}
        record_path={@record_path}
        namespace={@namespace}
      />
    </div>

    <div class="mt-4 p-6 border border-gray-300 rounded-lg dark:bg-gray-800 dark:border-gray-700">
      <div class="flex flex-wrap justify-between gap-16">
        <div class="basis-2/4 flex-1 flex flex-col">
          <dl class="divide-y divide-zinc-200 dark:divide-zinc-700">
            <div
              :for={field <- @show_view[:fields] -- Keyword.keys(LiveUI.uploads(@record))}
              :if={field_type(@record, field) in [:string, :integer, :id]}
              class="py-2 flex flex-wrap items-center gap-12 leading-6 sm:gap-8"
            >
              <dt class="w-1/4 flex-none font-medium text-zinc-500">
                <%= humanize(field) %>
              </dt>
              <dd class="text-gray-700 dark:text-gray-300">
                <.editable_field
                  field={field}
                  show_view={@show_view}
                  editing_field={@editing_field}
                  record={@record}
                  current_user={@current_user}
                />
              </dd>
            </div>
          </dl>

          <div
            :for={{upload_field, config} <- LiveUI.uploads(@record)}
            :if={field_type(@record, upload_field) == :array}
            class="mt-8"
          >
            <div class="mb-2 font-medium text-zinc-500">
              <%= humanize(upload_field) %>
            </div>

            <Field.render_images
              :if={image_field?(config[:accept])}
              srcs={Map.get(@record, upload_field)}
              alt={upload_field}
              wrapper_class="basis-1/4 gap-4"
              image_class="w-36"
              placeholder_class="size-36"
            />
          </div>
        </div>

        <div class="basis-1/4 space-y-1 flex-1 flex flex-col gap-2 text-gray-700 dark:text-gray-300">
          <div
            :for={{upload_field, config} <- LiveUI.uploads(@record)}
            :if={field_type(@record, upload_field) == :string}
          >
            <%= if image_field?(config[:accept]) do %>
              <Field.render_image
                src={Map.get(@record, upload_field)}
                alt={upload_field}
                class="max-w-full"
                placeholder_class="size-64"
              />
            <% else %>
              <span class="font-medium text-zinc-500"><%= humanize(upload_field) %>:</span>
              <Field.render_file href={Map.get(@record, upload_field)} />
            <% end %>
          </div>

          <div
            :for={field <- @show_view[:fields] -- Keyword.keys(LiveUI.uploads(@record))}
            :if={field_type(@record, field) in [:enum, :boolean, :naive_datetime, :array, :map]}
          >
            <span class="font-medium text-zinc-500"><%= humanize(field) %>:</span>
            <.editable_field
              field={field}
              show_view={@show_view}
              editing_field={@editing_field}
              record={@record}
              current_user={@current_user}
            />
          </div>
        </div>
      </div>
    </div>

    <div class="mt-4 flex flex-wrap justify-between gap-4">
      <.link navigate={@index_path} class="block">
        Back to <%= @resources %>
      </.link>

      <div :if={@debug}>
        <LiveUI.Components.Inspector.render
          name={"Record assigns #{inspect(self())}"}
          term={assigns}
          id={"#{@resource}-record-assigns"}
        />
      </div>
    </div>
    """
  end

  def editable_field(assigns) do
    assigns = assign(assigns, editable: assigns.field in assigns.show_view[:fields])

    ~H"""
    <Field.render
      :if={!@editable}
      record={@record}
      field={@field}
      formatter={@show_view[:formatters][@field]}
      action={:show}
    />

    <div
      :if={@editable}
      class="hover:cursor-pointer inline"
      id={@field}
      phx-click="edit-field"
      phx-value-field={@field}
    >
      <Field.render
        :if={@editing_field != @field}
        record={@record}
        field={@field}
        formatter={@show_view[:formatters][@field]}
        action={:show}
      />

      <div :if={@editing_field == @field}>
        <.live_component
          module={LiveUI.Components.EditableField}
          id={@field}
          field={@field}
          record={@record}
          relation={LiveUI.parent_relations(@record)[@field]}
          parent_relations={LiveUI.parent_relations(@record)}
          current_user={@current_user}
        />
      </div>
    </div>
    """
  end

  def relation_heading(assigns) do
    ~H"""
    <.p :if={@record} class="m-0">
      <%= humanize(@field) %>
      <.icon name="hero-chevron-right" class="h-4 w-4" />
      <%= relation_link(%{record: @record}) %>
    </.p>
    """
  end
end
