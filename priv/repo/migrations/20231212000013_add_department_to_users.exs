defmodule LiveUI.Repo.Migrations.AddDepartmentToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :department_id, references(:departments, with: [company_id: :company_id])
    end

    create index(:users, [:company_id, :department_id])
  end
end
