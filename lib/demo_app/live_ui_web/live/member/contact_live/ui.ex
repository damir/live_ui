defimpl LiveUI, for: LiveUI.Member.Contact do
  use LiveUI.Protocol

  def ownership(_), do: {:user_id, :current_user}
  def ignored_fields(_), do: [:user_id]

  def index_view(contact) do
    super(contact)
    |> put_in([:actions, :new, :changeset], &LiveUI.Member.Contact.create_changeset/3)
    |> add_action(:api_key, "Get api key", LiveUIWeb.Member.ContactLive.ApiKey)
  end

  def show_view(contact) do
    super(contact)
    |> put_in([:actions, :edit, :changeset], &LiveUI.Member.Contact.create_changeset/3)
    |> add_action(:send_email, "Send email", LiveUIWeb.Member.ContactLive.SendEmail)
  end
end
