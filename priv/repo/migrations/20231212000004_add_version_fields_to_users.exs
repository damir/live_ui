defmodule WebPay.Repo.Migrations.AddVersionFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :first_version_id, references(:versions), null: false
      add :current_version_id, references(:versions), null: false
    end

    create unique_index(:users, [:first_version_id])
    create unique_index(:users, [:current_version_id])
  end
end
