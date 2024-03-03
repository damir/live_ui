defmodule LiveUI.Components.Table do
  @moduledoc """
  Table to list the records and search form.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias LiveUI.Components.Field

  import LiveUI.Components.Core

  # naming
  attr :resource, :string
  attr :resources, :string

  # paths
  attr :index_path, :string

  # data
  attr :streams, :list
  attr :parent_relations, :list
  attr :page_title, :string

  # config
  attr :actions, :list
  attr :live_action, :atom
  attr :debug, :list

  # form
  attr :form_module, :atom
  attr :record, :any

  # flop
  attr :flop_meta, :map
  attr :flop_filters, :list
  attr :searching, :boolean, default: false

  # selecting records
  attr :selecting, :boolean, default: false
  attr :selected, :list

  def render(assigns) do
    assigns = assign(assigns, table_opts: LiveUI.Config.Flop.table_css_opts())

    any_batch_action =
      Enum.find(assigns.index_view[:batch_actions], fn
        {_action, config} ->
          case config[:allowed] do
            true -> true
            false -> false
            fun -> fun.(assigns)
          end
      end)

    assigns =
      assign(assigns,
        any_batch_action: any_batch_action,
        selected_class: "bg-sky-200 dark:bg-sky-800",
        selected_target: "##{assigns.resources}-table tbody tr"
      )

    ~H"""
    <.p class="text-sm"><%= @flop_meta.total_count %> records found</.p>

    <div class="mb-4 flex flex-wrap items-center justify-between gap-4">
      <.h3><%= Phoenix.Naming.humanize(@resources) %></.h3>

      <div
        :if={@flop_meta.total_count > 0 || !Enum.empty?(@flop_meta.flop.filters)}
        class="flex flex-wrap items-center gap-2"
      >
        <.action_button
          :for={batch_action <- Keyword.keys(@index_view[:batch_actions])}
          :if={@selecting}
          disabled={length(@selected) == 0}
          color="primary"
          config={@index_view[:batch_actions][batch_action]}
          action={batch_action}
          url_path={@index_path}
        >
          <%= @index_view[:batch_actions][batch_action][:name] %> (<%= length(@selected) %>)
        </.action_button>

        <.action_button
          :for={action <- Keyword.keys(@index_view[:actions])}
          :if={!@selecting}
          config={@index_view[:actions][action]}
          action={action}
          url_path={@index_path}
        >
          <%= @index_view[:actions][action][:name] %>
        </.action_button>

        <.button
          :if={@selecting}
          link_type="a"
          variant="outline"
          phx-click={
            if length(@selected) != @flop_meta.total_count do
              JS.push("select-all") |> JS.add_class(@selected_class, to: @selected_target)
            else
              JS.push("select-none") |> JS.remove_class(@selected_class, to: @selected_target)
            end
          }
        >
          Select all/none
        </.button>

        <.button
          :if={@any_batch_action}
          link_type="a"
          color={if @selecting, do: "primary", else: "white"}
          variant="outline"
          phx-click={JS.push("selecting") |> JS.remove_class(@selected_class, to: @selected_target)}
        >
          Select records
        </.button>

        <.button
          :if={Enum.any?(@flop_meta.flop.filters)}
          link_type="a"
          color="white"
          variant="outline"
          phx-click={"#{@resources}-reset-filter"}
        >
          Reset filters
        </.button>

        <.button
          link_type="a"
          color={if @searching, do: "primary", else: "white"}
          variant="outline"
          phx-click="searching"
        >
          Search
        </.button>
      </div>
    </div>

    <div class="flex gap-4">
      <div class={[
        "w-full overflow-auto ring-1 ring-gray-300 rounded dark:ring-gray-700",
        if(@searching, do: "w-3/4")
      ]}>
        <div :if={@flop_meta.total_count == 0} class="my-12 text-center">
          <.h3>No records found.</.h3>
          <.p :if={
            @flop_meta.flop.filters == [] &&
              Enum.find(Keyword.keys(@index_view[:actions]), &(&1 == :new))
          }>
            You can <.link patch={"#{@index_path}/new"} phx-click={JS.push_focus()}>create</.link>
            a new one!
          </.p>
        </div>

        <Flop.Phoenix.table
          :if={@flop_meta.total_count > 0}
          id={"#{@resources}-table"}
          opts={@table_opts}
          items={@streams.items}
          row_item={fn {_, item} -> item end}
          meta={@flop_meta}
          path={@index_path}
        >
          <%!-- row_click={&JS.navigate("#{@index_path}/#{elem(&1, 1).id}")} --%>

          <:col
            :let={item}
            :for={field <- @index_view[:fields]}
            label={Phoenix.Naming.humanize(field)}
            field={field}
            {maybe_align_right(@record, field, @table_opts)}
          >
            <div
              class={if @selecting, do: "cursor-pointer"}
              phx-click={
                if not @selecting,
                  do: JS.navigate("#{@index_path}/#{item.id}"),
                  else:
                    JS.push("select-record", value: %{id: item.id})
                    |> JS.toggle_class(@selected_class, to: "##{@resources}-#{item.id}")
              }
            >
              <Field.render
                record={item}
                field={field}
                formatter={@index_view[:formatters][field]}
                action={:index}
              />
            </div>
          </:col>
        </Flop.Phoenix.table>
      </div>

      <div :if={@searching} class="w-96">
        <div class="p-5 max-w-sm font-light ring-1 ring-gray-300 rounded dark:ring-gray-700">
          <.search_form
            :if={@flop_filters != []}
            flop_filters={@flop_filters}
            flop_meta={@flop_meta}
            parent_relations={@parent_relations}
            resources={@resources}
            on_change={"#{@resources}-update-filter"}
            on_reset={"#{@resources}-reset-filter"}
            id={"#{@resources}-filters"}
          />
        </div>
      </div>
    </div>

    <div :if={!@searching} class="mt-4 flex flex-wrap justify-between gap-4">
      <div :if={@debug}>
        <LiveUI.Components.Inspector.render
          name={"Table assigns #{inspect(self())}"}
          term={assigns}
          id={"#{@resource}-table-assigns"}
        />
      </div>

      <.pagination
        :if={@flop_meta.total_pages > 1}
        link_type="live_patch"
        path={
          fn page ->
            Flop.Phoenix.build_path(@index_path, Map.put(@flop_meta.flop, :page, page),
              backend: @flop_meta.backend
            )
          end
        }
        current_page={@flop_meta.current_page}
        total_pages={@flop_meta.total_pages}
      />
    </div>
    """
  end

  defp maybe_align_right(record, field, table_opts) do
    if LiveUI.Utils.field_type(record, field) in [:integer, :naive_datetime] do
      [
        thead_th_attrs: [class: table_opts[:thead_th_attrs][:class] ++ ["text-right"]],
        tbody_td_attrs: [class: table_opts[:tbody_td_attrs][:class] ++ ["text-right"]]
      ]
    else
      []
    end
  end

  attr :id, :string, default: nil
  attr :resources, :atom
  attr :parent_relations, :list
  attr :flop_meta, Flop.Meta
  attr :flop_filters, :list
  attr :on_change, :string
  attr :on_reset, :string
  attr :debounce, :integer, default: 200

  def search_form(assigns) do
    assigns = assign(assigns, form: to_form(assigns.flop_meta))

    ~H"""
    <div id={@id}>
      <.focus_wrap id={"#{@id}-focus-wrap"} phx-window-keydown="searching" phx-key="escape">
        <.form for={@form} id={"#{@id}-form"} phx-change={@on_change} phx-submit={@on_change}>
          <div class="space-y-4">
            <Flop.Phoenix.filter_fields :let={input} form={@form} fields={@flop_filters}>
              <div :if={input.rest[:relation_field]}>
                <.field_label><%= input.label %></.field_label>

                <LiveSelect.live_select
                  id={"ls-#{input.rest[:relation_field]}-filter"}
                  field={@form[input.rest[:relation_field]]}
                  update_min_len={1}
                  debounce={@debounce}
                  mode={:single}
                  placeholder={"Search by #{@parent_relations[input.rest[:relation_field]][:search_field_for_title]}"}
                  allow_clear
                  disabled={
                    LiveUI.Utils.LiveSelect.maybe_disabled(
                      assigns,
                      @parent_relations[input.rest[:relation_field]]
                    )
                  }
                  {LiveUI.Config.LiveSelect.css_opts()}
                >
                  <:option :let={option}>
                    <div><%= option.label %></div>
                    <div class="text-xs"><%= option.description %></div>
                  </:option>
                </LiveSelect.live_select>
              </div>

              <.field
                :if={!input.rest[:relation_field]}
                autocomplete="off"
                prompt="-- all --"
                field={input.field}
                label={input.label}
                type={input.type}
                phx-debounce={@debounce}
                {input.rest}
              />
            </Flop.Phoenix.filter_fields>
          </div>
        </.form>
        <div class="my-4">
          <.button link_type="a" to="#" color="white" variant="outline" phx-click="searching">
            Close
          </.button>

          <.button
            :if={Enum.any?(@flop_meta.flop.filters)}
            link_type="a"
            to="#"
            color="white"
            variant="outline"
            phx-click={@on_reset}
          >
            Reset filters
          </.button>
        </div>
      </.focus_wrap>
    </div>
    """
  end
end
