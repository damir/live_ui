defimpl LiveUI, for: LiveUI.Admin.Session do
  use LiveUI.Protocol

  def index_view(session) do
    super(session)
    |> put_in([:actions, :new, :allowed], false)
    |> put_in([:batch_actions, :delete, :allowed], false)
  end

  def show_view(session) do
    super(session)
    |> put_in([:actions, :edit, :allowed], false)
  end
end
