defimpl LiveUI, for: LiveUI.Admin.Product do
  use LiveUI.Protocol

  def uploads(_) do
    [
      image: [
        accept: ~w(.jpg .jpeg),
        max_file_size: 800_000
      ],
      extra_images: [
        accept: ~w(.jpg .jpeg),
        max_entries: 3,
        max_file_size: 800_000
      ],
      handbook: [
        accept: ~w(.pdf),
        max_file_size: 800_000
      ]
    ]
  end

  def index_view(product) do
    super(product)
    |> ignore_fields([:currency, :handbook, :metadata, :variants, :image, :extra_images])
    |> add_formatters(price: &LiveUIWeb.Formatters.money/2)
  end

  def show_view(product) do
    super(product)
    |> ignore_fields([:currency])
    |> add_formatters(price: &LiveUIWeb.Formatters.money/2)
  end
end
