defmodule LiveUI.Admin.Contact do
  @moduledoc false

  use Ecto.Schema

  schema "contacts" do
    field :name, :string
    field :email, :string
    field :phone, :string
    belongs_to :user, LiveUI.Admin.User

    timestamps()
  end
end
