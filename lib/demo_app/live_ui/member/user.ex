defmodule LiveUI.Member.User do
  @moduledoc false

  use Ecto.Schema

  schema "users" do
    # fields
    field :name, :string
    field :bio, :string
    field :website, :string

    # relations
    has_many :contacts, LiveUI.Member.Contact

    # system
    timestamps()
  end

  # this could use current user from the socket to update key in db
  def get_api_key(_user) do
    length = 40
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64() |> binary_part(0, length)
  end
end
