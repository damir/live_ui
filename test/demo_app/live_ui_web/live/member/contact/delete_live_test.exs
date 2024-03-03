defmodule LiveUIWeb.Member.Contact.DeleteLiveTest do
  use LiveUIWeb.ConnCase
  import Phoenix.LiveViewTest
  alias LiveUI.Member.Contact
  alias LiveUI.Repo

  test "delete record", %{conn: conn} do
    me = LiveUI.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, me)

    my_contact =
      %Contact{name: "my", email: "email", phone: "123", user_id: me.id} |> Repo.insert!()

    their_contact = %Contact{name: "their", email: "email", phone: "123"} |> Repo.insert!()

    # fail to delete my contact
    {:error,
     {:live_redirect, %{to: "/member/contacts", flash: %{"error" => "Record not found."}}}} =
      live(conn, ~p"/member/contacts/#{their_contact.id}/delete")

    # delete my contact
    {:ok, lv, _html} = live(conn, ~p"/member/contacts/#{my_contact.id}/delete")

    # delete
    {:ok, lv, _html} =
      lv
      |> element("#delete-content a", "Delete")
      |> render_click()
      |> follow_redirect(conn, "/member/contacts")

    # flash
    assert_flash(lv, :success, "Contact deleted successfully")
  end
end
