defmodule LiveUIWeb.Admin.User.NewLiveTest do
  use LiveUIWeb.ConnCase
  alias LiveUI.Admin.{Company, Department, User}
  alias LiveUI.Repo
  import Phoenix.LiveViewTest

  test "create new record", %{conn: conn} do
    {:ok, company} = Repo.insert(%Company{name: "name"})

    {:ok, department} =
      Repo.insert(%Department{name: "Research", location: "Boston", company: company})

    admin = %User{email: "admin@example.com", role: :admin} |> PaperTrail.insert!()
    conn = log_in_user(conn, admin)

    {:ok, lv, _html} = live(conn, ~p"/admin/users")

    # open form
    lv |> element("a", "New") |> render_click()

    # assert html
    assert has_element?(lv, "h3", "Create user record")
    assert page_title(lv) =~ "New user"

    # invalid change
    lv |> form("#user-form", user: %{}) |> render_change()
    assert_form_errors(lv)

    # invalid submit
    lv |> form("#user-form", user: %{}) |> render_submit()
    assert_form_errors(lv)

    # valid submit
    {:ok, lv, _html} =
      lv
      |> form("#user-form",
        user: %{
          # required
          "name" => user_name = "new name",
          "email" => "email@example.com",
          "bio" => "bio",
          "role" => "member",
          "website" => "example.com"
          # optional
          # "age" => "123",
          # "active" => "true"
        }
      )
      |> render_submit(user: %{"department_id" => department.id, "company_id" => company.id})
      |> follow_redirect(conn, ~p"/admin/users")

    # new user
    assert has_element?(lv, "td", user_name)
    assert_flash(lv, :success, "User created successfully")
  end

  defp assert_form_errors(lv, fields \\ false) do
    fields =
      if fields do
        fields
      else
        fields = LiveUI.index_view(%User{})[:actions][:new][:fields] -- [:active]
        optional_fields = LiveUI.index_view(%User{})[:actions][:new][:optional_fields]
        fields -- optional_fields
      end

    for field <- fields do
      assert has_element?(lv, ~s([phx-feedback-for="user[#{field}]"]), "can't be blank")
    end
  end
end
