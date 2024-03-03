defmodule LiveUIWeb.UserLoginLive do
  use LiveUIWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mt-12 mx-auto max-w-sm">
      <div class="text-center">
        <.h4>Sign in to account</.h4>
        <.p>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </.p>
      </div>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.field field={@form[:email]} type="email" label="Email" required />
        <.field field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.field
            field={@form[:remember_me]}
            wrapper_class="m-0 pt-1"
            type="checkbox"
            label="Keep me logged in"
          />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
