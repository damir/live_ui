defimpl LiveUI, for: LiveUI.Admin.Department do
  use LiveUI.Protocol,
    flop: [
      filterable: [:name, :company_id],
      sortable: [:updated_at],
      default_order: %{order_by: [:updated_at], order_directions: [:desc]}
    ]

  def title(company), do: company.name
  def description(company), do: company.location
  def search_function(_), do: &search_by_name/2

  def search_by_name(assigns, text) do
    import Ecto.Query
    company_id = Map.get(assigns[:current_user], :company_id)
    ilike = "#{text}%"

    from(d in LiveUI.Admin.Department,
      where: [company_id: ^company_id],
      where: ilike(d.name, ^ilike),
      select: %{
        label: d.name,
        value: d.id,
        description: d.location
      },
      limit: 5
    )
    |> LiveUI.Repo.all()
  end

  def index_view(record) do
    super(record)
    |> ignore_fields([:id])
    |> add_formatters(location: "text-green-700")
  end
end
