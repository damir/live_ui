defmodule LiveUIWeb.Admin.User.ShowLiveTest do
  use LiveUIWeb.ConnCase
  alias LiveUI.Admin.{User, Company, Department}
  alias LiveUI.Repo
  import Phoenix.LiveViewTest

  test "show record", %{conn: conn} do
    {:ok, company} = Repo.insert(%Company{name: "name"})

    {:ok, department} =
      Repo.insert(%Department{name: "Research", location: "Boston", company: company})

    user =
      %User{
        name: "name",
        email: "email@example.com",
        role: :member,
        active: true,
        bio: "**strong markdown**",
        website: "http://example.com",
        company: company,
        department: department
      }
      |> PaperTrail.insert!()

    admin = %User{email: "admin@example.com", role: :admin} |> PaperTrail.insert!()
    {:ok, lv, _html} = live(log_in_user(conn, admin), user_path = ~p"/admin/users/#{user.id}")

    # page title
    assert page_title(lv) =~ user.name

    # heading
    assert has_element?(lv, "h3", user.name)
    assert has_element?(lv, "p", user.email)

    # relations links
    assert has_element?(lv, "p", "Department")
    assert has_element?(lv, "p", department.name)
    assert has_element?(lv, ~s{a[href="/admin/departments/#{department.id}"]}, department.name)
    assert has_element?(lv, "p", "Company")
    assert has_element?(lv, "p", company.name)
    assert has_element?(lv, ~s{a[href="/admin/companies/#{company.id}"]}, company.name)

    # strings and numbers - not formatted
    not_formatted_fields =
      LiveUI.show_view(user)[:fields] -- (LiveUI.show_view(user)[:formatters] |> Keyword.keys())

    for field <- not_formatted_fields,
        LiveUI.Utils.field_type(user, field) in [:string, :integer] do
      assert(has_element?(lv, "dt", Phoenix.Naming.humanize(field)))
      assert(has_element?(lv, "dd > div##{field}", Map.get(user, field)))
    end

    # string - copy formatter
    assert(has_element?(lv, "dt", "Email"))
    assert(has_element?(lv, "dd > div > span#copy-email", user.email))

    # string - markdown formatter
    assert(has_element?(lv, "dt", "Bio"))
    assert(has_element?(lv, "dd > div > p > strong", "strong markdown"))

    # string - link formatter
    assert(has_element?(lv, "dt", "Website"))
    assert(has_element?(lv, "dd > div > a[href*=#{user.website}]", user.website))

    # booleans
    assert has_element?(lv, "span", "Active:")
    assert has_element?(lv, "div", "Yes")

    # timestamps
    assert has_element?(lv, "span", "Inserted at:")

    assert has_element?(
             lv,
             "div",
             LiveUI.Components.Field.render_field(:naive_datetime, user.inserted_at)
           )

    assert has_element?(lv, "span", "Updated at:")

    assert has_element?(
             lv,
             "div",
             LiveUI.Components.Field.render_field(:naive_datetime, user.updated_at)
           )

    # back to index link
    assert has_element?(lv, "a", "Back to users")

    # edit action
    title = "Edit user record"
    element(lv, "a", "Edit") |> render_click()
    assert has_element?(lv, "h3", title)
    assert page_title(lv) =~ title
    assert_patched(lv, "#{user_path}/edit")
    element(lv, "a[href*=#{user_path}]", "Back") |> render_click()

    # delete action
    title = "Delete user record"
    element(lv, "a", "Delete") |> render_click()
    assert has_element?(lv, "p", "Deleting a user")
    assert page_title(lv) =~ title
    assert_patched(lv, "#{user_path}/delete")
    element(lv, "a[href*=#{user_path}]", "Back") |> render_click()
  end
end
