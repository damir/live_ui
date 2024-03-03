defmodule LiveUIWeb.Admin.UserLive.Deactivate do
  @moduledoc false

  use Phoenix.LiveComponent
  alias Phoenix.LiveView.JS
  import LiveUI.Components.Core
  import Ecto.Query

  def update(assigns, socket) do
    users =
      from(users in LiveUI.Admin.User, where: users.id in ^assigns.selected)
      |> LiveUI.Config.repo().all

    {:ok, socket |> assign(assigns) |> assign(:users, users)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.p>Deactivating multiple users</.p>
      <.h3>
        Are you sure you want to deactivate <%= length(@selected) %> user(s)?
      </.h3>

      <.ul class="my-6">
        <li :for={user <- @users}>
          <%= user.name %> (<%= user.email %>)
        </li>
      </.ul>

      <.button link_type="live_patch" to={@index_path} variant="outline">
        Back
      </.button>

      <.link
        class="px-2 text-red-600"
        tabindex="-1"
        phx-target={@myself}
        phx-click={JS.push("deactivate", value: %{selected: @selected})}
      >
        Deactivate
      </.link>
    </div>
    """
  end

  def handle_event("deactivate", %{"selected" => selected}, socket) do
    from(users in LiveUI.Admin.User, where: users.id in ^selected)
    |> LiveUI.Config.repo().update_all(set: [active: false])

    {:noreply,
     socket
     |> put_flash(:info, "#{length(selected)} user(s) are deactivated successfully.")
     |> push_navigate(to: socket.assigns.index_path)}
  end
end
