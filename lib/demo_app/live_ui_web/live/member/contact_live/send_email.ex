defmodule LiveUIWeb.Member.ContactLive.SendEmail do
  @moduledoc false

  use Phoenix.LiveComponent
  import LiveUI.Components.Core

  def render(assigns) do
    ~H"""
    <div>
      <.h4>Send email</.h4>
      <.p>From: <%= @current_user.email %></.p>
      <.p>To: <%= @record.email %></.p>

      <.field field={:message} type="textarea" name="message" value="" label="" />

      <.button variant="outline" phx-click="send_email" phx-target={@myself}>
        Send
      </.button>
      <.link patch={@index_path}>Back</.link>
    </div>
    """
  end

  def handle_event("send_email", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Email sent to #{socket.assigns.record.email}.")
     |> push_navigate(to: socket.assigns.index_path)}
  end
end
