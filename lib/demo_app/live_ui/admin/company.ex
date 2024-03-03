defmodule LiveUI.Admin.Company do
  @moduledoc false

  use Ecto.Schema

  schema "companies" do
    field :name, :string
    field :description, :string
    has_many :users, LiveUI.Admin.User
    has_many :departments, LiveUI.Admin.Department

    timestamps()
  end
end
