defmodule LiveUI.Repo.Migrations.AddCompanyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :company_id, references(:companies)
    end

    create unique_index(:users, [:id, :company_id])
  end
end
