defmodule LiveUI.Components.Core do
  @moduledoc """
  Core components.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  # external components

  @components_provider PetalComponents

  components = [
    Typography: [:h1, :h2, :h4, :h3, :h5, :p, :ul],
    Button: [:button, :icon_button],
    Badge: [:badge],
    Alert: [:alert],
    Field: [:field, :field_label, :field_error],
    Pagination: [:pagination],
    Progress: [:progress],
    Card: [:card, :card_content]
  ]

  for {mod, components} <- components,
      component <- components,
      do: defdelegate(unquote(component)(assigns), to: Module.concat(@components_provider, mod))

  # from phoenix core

  @doc "Taken from phoenix core."
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc "Taken from phoenix core."
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 transition-opacity bg-zinc-50/90 dark:bg-gray-900/90"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              class={[
                "shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition",
                "bg-sky-50 dark:bg-gray-800 dark:ring-gray-700",
                @class
              ]}
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 font-bold opacity-20 hover:opacity-40 dark:text-gray-50"
                  aria-label="close"
                  tabindex="0"
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc "Taken from phoenix core."
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @doc "Taken from phoenix core."
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc "Taken from phoenix core."
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-200", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc "Taken from phoenix core."
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  # LiveUI

  @doc "Renders action button."
  attr :config, :list
  attr :action, :atom
  attr :url_path, :string
  attr :disabled, :boolean, default: false
  attr :color, :string, default: "white"
  slot :inner_block, required: true

  def action_button(assigns) do
    allowed =
      case assigns.config[:allowed] do
        true -> true
        false -> false
        fun -> fun.(assigns)
      end

    assigns = assign(assigns, :allowed, allowed)

    ~H"""
    <.button
      :if={@allowed}
      link_type="live_patch"
      variant="outline"
      class="tabular-nums"
      color={@color}
      disabled={@disabled}
      to={"#{@url_path}/#{@action}"}
      phx-click={JS.push_focus()}
    >
      <%= render_slot(@inner_block) %>
    </.button>
    """
  end

  @doc "Renders link to parent record."
  attr :record, :map

  def relation_link(assigns) do
    ~H"""
    <.link navigate={"/#{LiveUI.namespace(@record)}/#{LiveUI.resources(@record)}/#{Map.get(@record, :id)}"}>
      <%= LiveUI.title(@record) %>
    </.link>
    """
  end

  @doc "Renders component for an action."
  attr(:live_action, :atom, required: true)
  attr(:action, :atom, required: true)
  attr(:return_to, :string, required: true)
  slot(:inner_block, required: true)
  slot(:header)
  slot(:subheader)

  def action_modal(assigns) do
    ~H"""
    <.modal
      :if={@live_action == @action}
      id={to_string(@action)}
      show
      on_cancel={JS.patch(@return_to)}
    >
      <p :if={@subheader != []} class="mt-2 text-sm leading-6 text-zinc-600">
        <%= render_slot(@subheader) %>
      </p>

      <h2 :if={@header != []} class="pb-4 text-lg font-semibold leading-8 text-zinc-800">
        <%= render_slot(@header) %>
      </h2>

      <%= render_slot(@inner_block) %>
    </.modal>
    """
  end

  @doc """
  Used for switching dark/light color schemes.

  This needs to be inlined in the <head> because it will set a class on the document,
  which affects all "dark" prefixed classed (eg. dark:text-white).
  If you do this in the body or a separate javascript file then when in dark mode,
  the page will flash in light mode first before switching to dark mode.

  Utilized by `color-scheme-hook.js`.

  Taken from
  https://github.com/petalframework/petal_boilerplate/blob/21a70bec1060872d1ee88a23d31f8d2fcfd4cfc0/lib/petal_boilerplate_web/components/core_components.ex#L630

      <.color_scheme_switch_js />
  """
  def color_scheme_switch_js(assigns) do
    ~H"""
    <script>
      window.applyScheme = function(scheme) {
        if (scheme === "light") {
          document.documentElement.classList.remove('dark')
          document
            .querySelectorAll(".color-scheme-dark-icon")
            .forEach((el) => el.classList.remove("hidden"));
          document
            .querySelectorAll(".color-scheme-light-icon")
            .forEach((el) => el.classList.add("hidden"));
          localStorage.scheme = 'light'
        } else {
          document.documentElement.classList.add('dark')
          document
            .querySelectorAll(".color-scheme-dark-icon")
            .forEach((el) => el.classList.add("hidden"));
          document
            .querySelectorAll(".color-scheme-light-icon")
            .forEach((el) => el.classList.remove("hidden"));
          localStorage.scheme = 'dark'
        }
      };

      window.toggleScheme = function () {
        if (document.documentElement.classList.contains('dark')) {
          applyScheme("light")
        } else {
          applyScheme("dark")
        }
      }

      window.initScheme = function() {
        if (localStorage.scheme === 'dark' || (!('scheme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
          applyScheme("dark")
        } else {
          applyScheme("light")
        }
      }

      try {
        initScheme()
      } catch (_) {}
    </script>
    """
  end

  @doc """
  A button that switches between light and dark modes.

  Pairs with css-theme-switch.js

  Taken from https://github.com/petalframework/petal_boilerplate/blob/21a70bec1060872d1ee88a23d31f8d2fcfd4cfc0/lib/petal_boilerplate_web/components/core_components.ex#L587

      <.color_scheme_switch_js />
  """
  def color_scheme_switch(assigns) do
    ~H"""
    <button
      phx-hook="ColorSchemeHook"
      type="button"
      id={Ecto.UUID.generate()}
      class="color-scheme text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 rounded-lg text-sm p-2.5"
    >
      <svg
        class="hidden w-5 h-5 color-scheme-dark-icon"
        fill="currentColor"
        viewBox="0 0 20 20"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path>
      </svg>
      <svg
        class="hidden w-5 h-5 color-scheme-light-icon"
        fill="currentColor"
        viewBox="0 0 20 20"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
          fill-rule="evenodd"
          clip-rule="evenodd"
        >
        </path>
      </svg>
    </button>
    """
  end
end
