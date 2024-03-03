defimpl LiveUI, for: LiveUI.Admin.User do
  use Phoenix.Component
  import LiveUI.Components.Core
  import LiveUI.Formatters

  use LiveUI.Protocol,
    flop: [
      filterable: [
        :company_id,
        :department_id,
        :name,
        :email,
        :age,
        :role,
        :active,
        :confirmed_at
      ],
      sortable: [:updated_at],
      default_order: %{order_by: [:updated_at], order_directions: [:desc]}
    ]

  def title(user), do: user.name
  def description(_), do: false

  def heading(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2">
      <.h3><%= @name %></.h3>
      <.p><%= @email %></.p>
    </div>
    """
  end

  def filter_operators(_user), do: [age: [:<=, :>=]]
  def input_hints(_user), do: [website: "Should begin with https://"]

  def index_view(user) do
    super(user)
    |> ignore_fields([:bio, :age])
    |> ignore_fields(:new, [:confirmed_at])
    |> set_optional_fields(:new, [:age])
    |> add_batch_action(:deactivate, "Deactivate", LiveUIWeb.Admin.UserLive.Deactivate)
    |> add_formatters(website: {&link_/1, %{name: "Web"}})
  end

  def show_view(user) do
    super(user)
    |> add_formatters(
      email: &copy/1,
      bio: &markdown/1,
      website: &link_/1
    )
  end
end
