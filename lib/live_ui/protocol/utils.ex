defmodule LiveUI.Protocol.Utils do
  @moduledoc """
  Utility functions for modifying default `LiveUI` implementation.
  """

  @doc ~S'''
  Adds custom action to `Index` or `Show` view that points to user defined `Phoenix.LiveComponent` module.

  Custom component will be accessible with an action button and its content will be rendered inside the modal.
  The action's URL is generated as `/<namespace>/<resource>/<id>/<action-key>` and is set automatically by `LiveUI.Router.live_ui/3`.
  The component for `Show` view has access to `@record` assign that holds database record.

  Add custom `:api_key` action to `Index` view:

      defimpl LiveUI, for: MyApp.Member.Contact do
        use LiveUI.Protocol

        def index_view(record) do
          super(record)
          |> add_action(:api_key, "Get api key", MyAppWeb.Member.ContactLive.ApiKey)
        end
      end

  Custom component that generates the api key could use `@current_user` from the socket:

      defmodule MyAppWeb.Member.ContactLive.ApiKey do
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
              <LiveUI.Formatters.copy class="font-bold" field="api-key" value={@api_key} />
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
            socket |> assign(api_key: MyApp.Member.User.get_api_key(socket.assigns.current_user))
          }
        end
      end

  `LiveUI.Formatters.copy/1` is built-in component that shows an icon next to the value to copy it to the clipboard.
  `p` and `h3` components are from `LiveUI.Components.Core` which delegates the calls to `PetalComponents`.

  It is also possible to add extra custom values to the socket assigns of the parent view by overriding mount callback,
  current_user will be automatically available if set in `Phoenix.LiveView.Router.live_session/3`.

  By default `:allowed` field is set to `true`; it also could point to a function that controls who has the access to the component.
  '''
  def add_action(view, action, name, component, allowed \\ true) do
    update_in(
      view,
      [:actions],
      &Keyword.put(&1, action, name: name, component: component, allowed: allowed)
    )
  end

  @doc ~S'''
  Adds custom batch action to `Index` view that points to user defined `Phoenix.LiveComponent` module.

  Custom component will be accessible with an action button and its content will be rendered inside the modal.
  The action's URL is generated as `/<namespace>/<resources>/<action-key>` and is set automatically by `LiveUI.Router.live_ui/3`.
  The component has access to `@selected` assign that holds ids of selected records.

  Add custom `:deactivate` batch action:

      defimpl LiveUI, for: MyApp.Admin.User do
        def index_view(user) do
          super(user)
          |> add_batch_action(:deactivate, "Deactivate", MyAppWeb.Admin.UserLive.Deactivate)
        end
      end

  Custom component that will deactivate users:

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
  '''
  def add_batch_action(view, action, name, component, allowed \\ true) do
    view
    |> update_in(
      [:batch_actions],
      &Keyword.put(&1, action, name: name, component: component, allowed: allowed)
    )
  end

  @doc """
  Don't show fields in actions.

      # remove :confirmed_at from create form
      def index_view(user) do
        super(user)
        |> ignore_fields(:new, [:confirmed_at])
      end

      # remove :email and :company_id from edit form
      def show_view(user) do
        super(user)
        |> ignore_fields([:edit], [:email, :company_id])
      end

  NOTE: fields can be disabled globally in `config.exs`:

      config :live_ui,
        ignored_fields: [:token, :hashed_password, :first_version_id, :current_version_id]
  """
  def ignore_fields(view, action, fields),
    do: view |> put_in([:actions, action, :fields], view[:actions][action][:fields] -- fields)

  @doc """
  Don't show fields in `Index` or `Show` view.

      def index_view(user) do
        super(user)
        |> ignore_fields([:updated_at, :inserted_at])
      end
  """
  def ignore_fields(view, fields),
    do: view |> put_in([:fields], view[:fields] -- fields)

  @doc """
  All fields are required in `Ecto.Changeset` unless they are marked as optional.

      def index_view(user) do
        super(user)
          |> set_optional_fields(:new, [:age])
      end
  """
  def set_optional_fields(view, action, fields),
    do: view |> put_in([:actions, action, :optional_fields], fields)

  @doc """
  Format fields with CSS classes, functions or components.

  Multiple formatters for a field are set as a list of formatters.

      import LiveUI.Formatters

      def index_view(user) do
        super(user)
        |> add_formatters(
          email: {&mask/2, [left: 4]},
          bio: &markdown/1,
          website: {&link_/1, %{name: "Web"}},
          role: &String.upcase/1
        )
      end

  NOTE: Formatting enum field will also format its values in dropdown input in related form.
  This could be improved in future versions with support for custom input components.

  ### Formatting with CSS class

  When formatter is a string it will wrap the value with a span element with CSS class.

      def index_view(user) do
        super(user)
        |> add_formatters(email: "text-green-700")
      end

  ### Formatting with a function

  Field value is passed as an argument to a function with arity of 1.

      def index_view(user) do
        super(user)
        |> add_formatters(role: &String.upcase/1)
      end

   Record and field values are passed to a function with arity of 2.

      # show prices as $1,234.00
      def index_view(product) do
        super(product)
        |> ignore_fields([:currency])
        |> add_formatters(price: &MyAppWeb.Formatters.money/2)
      end

      def money(record, value) do
        Money.new(Map.get(record, :currency), value)
      end

  Extra options are set as keyword list in 2-tuple.

      def index_view(user) do
        super(user)
        |> add_formatters(email: {&mask/2, [left: 4]})
      end

  ### Formatting with a component

  If the function has a map as an argument it is treated as a component.
  Component assigns are passed as `%{field: field, value: value, record: record}`.

      # built-in component
      def index_view(user) do
        super(user)
        |> add_formatters(email: &LiveUI.Formatters.copy/1
      end

      # custom component
      def index_view(user) do
        super(user)
        |> add_formatters(email: &MyAppWeb.Components.email/1
      end

  Extra options are set as map in 2-tuple.

      def index_view(user) do
        super(user)
        |> add_formatters(website: {&link/1, %{name: "Web"}})
      end
  """
  def add_formatters(view, formatters), do: Keyword.put(view, :formatters, formatters)

  @doc """
  Change field's default input type.

      # change input from text to textarea
      def index_view(company) do
        super(company)
          |> configure_inputs([:new], description: "textarea")
      end

  NOTE: - `textarea` is currently used for `map` and `array` ecto types until we add configurable components for inputs.
  """
  def configure_inputs(view, action, inputs_config) do
    view |> put_in([:actions, action, :inputs], view[:actions][action][:inputs] ++ inputs_config)
  end
end
