defmodule LiveUIWeb.Admin.User.DeleteLiveTest do
  use LiveUIWeb.ConnCase
  alias LiveUI.Admin.User
  import Phoenix.LiveViewTest

  test "delete record", %{conn: conn} do
    user = %User{email: "user@example.com"} |> PaperTrail.insert!()

    admin = %User{email: "admin@example.com", role: :admin} |> PaperTrail.insert!()
    {:ok, lv, html} = live(conn = log_in_user(conn, admin), ~p"/admin/users/#{user.id}/delete")

    # headings
    assert html =~ "Deleting a user"

    # delete
    {:ok, lv, _html} =
      lv
      |> element("#delete-content a", "Delete")
      |> render_click()
      |> follow_redirect(conn, "/admin/users")

    # flash
    assert_flash(lv, :success, "User deleted successfully")
  end
end
