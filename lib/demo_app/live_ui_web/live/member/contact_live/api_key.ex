defmodule LiveUIWeb.Member.ContactLive.ApiKey do
  @moduledoc false

  use Phoenix.LiveComponent
  import LiveUI.Components.Core

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:api_key, false)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.p>Use this key to access our API</.p>
      <.h3>Get api key</.h3>

      <.p :if={@api_key}>
        <LiveUI.Formatters.copy class="text-teal-600 font-bold" field="api-key" value={@api_key} />
      </.p>

      <.p :if={!@api_key}>
        <.button variant="outline" phx-click="get_api_key" phx-target={@myself}>
          Generate new key
        </.button>
      </.p>

      <.p class="my-4">
        Key will expire in 180 days. Notification will be sent to <%= @current_user.email %>.
      </.p>
      <.link patch={@index_path}>Back</.link>
    </div>
    """
  end

  def handle_event("get_api_key", _params, socket) do
    {
      :noreply,
      socket |> assign(api_key: LiveUI.Member.User.get_api_key(socket.assigns.current_user))
    }
  end
end
