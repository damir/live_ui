defmodule LiveUI.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string
      add :description, :string
      timestamps()
    end
  end
end
