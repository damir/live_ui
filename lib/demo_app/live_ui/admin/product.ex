defmodule LiveUI.Admin.Product do
  @moduledoc false

  use Ecto.Schema

  schema "products" do
    field :name, :string
    field :description, :string
    belongs_to :company, LiveUI.Admin.Company
    field :price, :integer
    field :currency, Ecto.Enum, values: [:USD, :EUR]
    field :stock, :integer
    field :unit, :string
    field :variants, {:array, :string}, default: []
    field :metadata, :map, default: %{}
    field :image, :string
    field :extra_images, {:array, :string}, default: []
    field :handbook, :string

    timestamps()
  end
end
