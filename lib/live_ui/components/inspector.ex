defmodule LiveUI.Components.Inspector do
  @moduledoc """
  Inspect term.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import LiveUI.Components.Core

  attr :term, :any
  attr :id, :string, default: "inspector"
  attr :name, :string, default: "Inspect"
  attr :visible, :boolean, default: false
  attr :class, :string, default: ""
  attr :link_class, :string, default: ""

  def render(assigns) do
    ~H"""
    <div :if={Mix.env() in [:dev, :test]} class={@class}>
      <a phx-click={JS.toggle(to: "#debug-#{@id}")} class={["cursor-pointer", @link_class]}>
        <%= @name %>
      </a>
      <div id={"debug-#{@id}"} class={["pt-2", if(!@visible, do: "hidden")]}>
        <%!-- <.cldr_locale_info /> --%>
        <LiveInspect.live_inspect term={@term} id={"debug-#{@id}-inspector"} />
      </div>
    </div>
    """
  end

  def cldr_locale_info(assigns) do
    ~H"""
    <.p>cldr_locale: <%= inspect(Process.get(:cldr_locale)) %></.p>
    <.p>territory: <%= Process.get(:cldr_locale).territory %></.p>
    <.p>
      zones: <%= inspect(
        Process.get(:cldr_locale).territory
        |> Cldr.Timezone.timezones_for_territory()
      ) %>
    </.p>
    """
  end
end
