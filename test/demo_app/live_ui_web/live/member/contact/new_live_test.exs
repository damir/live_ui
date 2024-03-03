defmodule LiveUIWeb.Member.Contact.NewLiveTest do
  use LiveUIWeb.ConnCase
  import Phoenix.LiveViewTest

  test "create new record", %{conn: conn} do
    me = LiveUI.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, me)

    {:ok, lv, _html} = live(conn, ~p"/member/contacts")

    # open form
    lv |> element("a", "create") |> render_click()

    # assert html
    assert has_element?(lv, "h3", "Create contact record")
    assert page_title(lv) =~ "New contact"

    # invalid change
    lv |> form("#contact-form", contact: %{}) |> render_change()
    assert has_element?(lv, ~s([phx-feedback-for="contact[name]"]), "can't be blank")

    # invalid submit
    lv |> form("#contact-form", user: %{}) |> render_submit()
    assert has_element?(lv, ~s([phx-feedback-for="contact[name]"]), "can't be blank")

    # valid submit
    {:ok, lv, _html} =
      lv
      |> form("#contact-form",
        contact: %{name: contact_name = "new name", email: "email@wxample.com", phone: "123"}
      )
      |> render_submit()
      |> follow_redirect(conn, ~p"/member/contacts")

    # new contact
    assert has_element?(lv, "h3", "Contacts")
    assert has_element?(lv, "td", contact_name)

    # flash
    assert_flash(lv, :success, "Contact created successfully")
  end
end
