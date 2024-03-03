defmodule LiveUI.Admin.Session do
  @moduledoc false

  use Ecto.Schema

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    field :locale, :string
    field :user_agent, :string
    field :remote_ip, :string
    belongs_to :user, LiveUI.Admin.User

    timestamps(updated_at: false)
  end
end
