defmodule LiveUI.Member.Contact do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    # relations
    belongs_to :user, LiveUI.Member.User

    # fields
    field :name, :string
    field :email, :string
    field :phone, :string

    # system
    timestamps()
  end

  def create_changeset(contact, params, socket) do
    LiveUI.Changeset.create_changeset(contact, params, socket)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
  end

  def update_changeset(contact, params, socket) do
    create_changeset(contact, params, socket)
  end
end
