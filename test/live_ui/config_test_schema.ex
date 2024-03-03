defmodule LiveUI.ConfigTest.User do
  @moduledoc false

  use Ecto.Schema

  schema "users" do
    field :name, :string
  end
end

defimpl LiveUI, for: LiveUI.ConfigTest.User do
  use LiveUI.Protocol
end
