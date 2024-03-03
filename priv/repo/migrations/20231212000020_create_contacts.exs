defmodule LiveUI.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :name, :string
      add :email, :string
      add :phone, :string
      add :user_id, references(:users)

      timestamps()
    end

    create index(:contacts, [:user_id])
  end
end
