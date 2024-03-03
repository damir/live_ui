defmodule LiveUI.Admin.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  # @derive {
  #   Flop.Schema,
  #   filterable: [:company_id, :department_id, :name, :email, :age, :role, :active, :confirmed_at],
  #   sortable: [:updated_at],
  #   default_order: %{order_by: [:updated_at], order_directions: [:desc]}
  # }

  schema "users" do
    # simple fields
    field :name, :string
    field :email, :string
    field :bio, :string
    field :age, :integer
    field :website, :string

    # relations
    belongs_to :company, LiveUI.Admin.Company
    belongs_to :department, LiveUI.Admin.Department
    has_many :user_tokens, LiveUI.Admin.Session
    has_many :contacts, LiveUI.Admin.Contact

    # booleans, enums, dates
    field :role, Ecto.Enum, values: [:member, :owner, :admin]
    field :active, :boolean
    field :confirmed_at, :naive_datetime

    # system
    belongs_to(:first_version, PaperTrail.Version)
    belongs_to(:current_version, PaperTrail.Version, on_replace: :update)
    timestamps()
  end

  def create_changeset(user, params, socket) do
    LiveUI.Changeset.create_changeset(user, params, socket)
    |> unsafe_validate_unique(:email, LiveUI.Repo)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> foreign_key_constraint(:department_id)
  end

  def update_changeset(user, params, socket) do
    LiveUI.Changeset.update_changeset(user, params, socket)
    |> foreign_key_constraint(:department_id)
  end
end
