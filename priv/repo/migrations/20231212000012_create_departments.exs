defmodule LiveUI.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :name, :text
      add :location, :text
      add :company_id, references(:companies)

      timestamps()
    end

    create unique_index(:departments, [:id, :company_id])
  end
end
