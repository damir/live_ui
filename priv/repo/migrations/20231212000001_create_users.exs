defmodule LiveUI.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :naive_datetime

      add :name, :string
      add :age, :integer
      add :bio, :string
      add :role, :string
      add :active, :boolean
      add :website, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
