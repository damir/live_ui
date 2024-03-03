defmodule LiveUI.Admin.Department do
  @moduledoc false

  use Ecto.Schema

  schema "departments" do
    field :name, :string
    field :location, :string
    belongs_to :company, LiveUI.Admin.Company
    has_many :users, LiveUI.Admin.User

    timestamps()
  end
end
