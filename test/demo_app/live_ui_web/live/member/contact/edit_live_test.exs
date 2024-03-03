defmodule LiveUIWeb.Member.Contact.EditLiveTest do
  use LiveUIWeb.ConnCase
  import Phoenix.LiveViewTest
  alias LiveUI.Member.Contact
  alias LiveUI.Repo

  test "update record", %{conn: conn} do
    me = LiveUI.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, me)

    my_contact =
      %Contact{name: "my", email: "email", phone: "123", user_id: me.id} |> Repo.insert!()

    their_contact = %Contact{name: "their", email: "email", phone: "123"} |> Repo.insert!()

    # fail to edit their contact
    {:error,
     {:live_redirect, %{to: "/member/contacts", flash: %{"error" => "Record not found."}}}} =
      live(conn, ~p"/member/contacts/#{their_contact.id}/edit")

    # edit my contact
    {:ok, lv, _html} = live(conn, ~p"/member/contacts/#{my_contact.id}/edit")

    # invalid change
    lv |> form("#contact-form", contact: %{"name" => ""}) |> render_change()
    assert has_element?(lv, ~s([phx-feedback-for="contact[name]"]), "can't be blank")

    # invalid submit
    lv |> form("#contact-form", contact: %{}) |> render_submit()
    assert has_element?(lv, ~s([phx-feedback-for="contact[name]"]), "can't be blank")

    # valid submit
    {:ok, lv, _html} =
      lv
      |> form("#contact-form", contact: %{"name" => "new name"})
      |> render_submit()
      |> follow_redirect(conn, ~p"/member/contacts/#{my_contact.id}")

    # flash
    assert_flash(lv, :success, "Contact updated successfully")
  end
end
