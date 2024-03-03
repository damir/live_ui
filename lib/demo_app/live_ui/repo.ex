defmodule LiveUI.Repo do
  use Ecto.Repo,
    otp_app: :live_ui,
    adapter: Ecto.Adapters.Postgres
end
