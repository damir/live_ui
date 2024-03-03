defimpl LiveUI, for: LiveUI.Admin.Company do
  use LiveUI.Protocol

  def title(company), do: company.name
  def description(company), do: company.description
  def resources(_), do: "companies"
  def search_field_for_title(_), do: :name

  def index_view(company) do
    super(company)
    |> ignore_fields([:id])
    |> configure_inputs(:new, description: "textarea")
  end
end
