defmodule LiveUIWeb.Admin.User.EditLiveTest do
  use LiveUIWeb.ConnCase
  alias LiveUI.Admin.{User, Company, Department}
  alias LiveUI.Repo
  import Phoenix.LiveViewTest

  test "update record", %{conn: conn} do
    {:ok, company} = Repo.insert(%Company{name: "name"})

    {:ok, department} =
      Repo.insert(%Department{name: "Research", location: "Boston", company: company})

    user =
      %User{
        name: "name",
        email: "email@example.com",
        bio: "bio",
        role: :member,
        website: "example.com",
        active: true,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        company: company,
        department: department
      }
      |> PaperTrail.insert!()

    admin = %User{email: "admin@example.com", role: :admin} |> PaperTrail.insert!()
    conn = log_in_user(conn, admin)

    {:ok, lv, html} = live(conn, ~p"/admin/users/#{user.id}/edit")

    # headings
    assert html =~ "Edit user record"
    assert html =~ "Save user"

    # invalid change
    lv |> form("#user-form", user: %{"name" => ""}) |> render_change()
    assert has_element?(lv, ~s([phx-feedback-for="user[name]"]), "can't be blank")

    # invalid submit
    lv |> form("#user-form", user: %{}) |> render_submit()
    assert has_element?(lv, ~s([phx-feedback-for="user[name]"]), "can't be blank")

    # valid submit
    {:ok, lv, _html} =
      lv
      |> form("#user-form", user: %{"name" => user_name = "updated name"})
      |> render_submit()
      |> follow_redirect(conn, ~p"/admin/users/#{user.id}")

    # open_browser(lv)

    # updated user
    assert has_element?(lv, "h3", user_name)
    assert has_element?(lv, "dd", user_name)

    # flash
    assert_flash(lv, :success, "User updated successfully")
  end
end
