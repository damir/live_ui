defmodule LiveUI.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :description, :text
      add :sku, :integer
      add :price, :integer
      add :currency, :string
      add :stock, :integer
      add :unit, :string
      add :variants, {:array, :string}
      add :metadata, :map
      add :image, :string
      add :extra_images, {:array, :string}
      add :handbook, :string
      add :active, :boolean
      add :company_id, references(:companies)

      timestamps()
    end

    create index(:products, [:company_id])
  end
end
