defmodule LiveUIWeb.Member.Contact.ShowLiveTest do
  use LiveUIWeb.ConnCase
  import Phoenix.LiveViewTest
  alias LiveUI.Member.Contact
  alias LiveUI.Repo

  test "show record", %{conn: conn} do
    me = LiveUI.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, me)

    my_contact = %Contact{name: "my", email: "email", user_id: me.id} |> Repo.insert!()
    their_contact = %Contact{name: "their", email: "email"} |> Repo.insert!()

    # fail to show their contact
    {:error,
     {:live_redirect, %{to: "/member/contacts", flash: %{"error" => "Record not found."}}}} =
      live(conn, ~p"/member/contacts/#{their_contact.id}")

    # show my contact
    {:ok, lv, _html} = live(conn, my_contact_path = ~p"/member/contacts/#{my_contact.id}")

    # headings
    assert has_element?(lv, "h3", my_contact.name)

    # custom action
    element(lv, "a", "Send email") |> render_click()
    assert has_element?(lv, "p", "From: #{me.email}")
    assert has_element?(lv, "p", "To: #{my_contact.email}")
    assert page_title(lv) =~ "Send email"
    assert_patched(lv, "#{my_contact_path}/send_email")
    element(lv, "a[href*=#{my_contact_path}]", "Back") |> render_click()
  end
end
