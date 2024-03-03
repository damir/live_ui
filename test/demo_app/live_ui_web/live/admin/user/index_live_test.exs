defmodule LiveUIWeb.Admin.User.IndexLiveTest do
  use LiveUIWeb.ConnCase
  alias LiveUI.Admin.{User, Company, Department}
  alias LiveUI.Repo
  import Phoenix.LiveViewTest

  @number_of_records 15

  test "list and search records", %{conn: conn} do
    {:ok, company} = Repo.insert(%Company{name: "name"})

    {:ok, department} =
      Repo.insert(%Department{name: "Research", location: "Boston", company: company})

    users =
      for n <- 1..@number_of_records do
        %User{
          name: "name-#{n}",
          email: "email-#{n}@example.com",
          website: "http://web-#{n}@example.com",
          role: :member,
          active: true,
          company_id: company.id,
          department_id: if(n == 1, do: department.id, else: nil)
        }
        |> PaperTrail.insert!()
      end

    admin = %User{email: "admin@example.com", role: :admin} |> PaperTrail.insert!()
    {:ok, lv, _html} = live(_conn = log_in_user(conn, admin), users_path = ~p"/admin/users")

    first_user = List.first(users)
    last_user = List.last(users)

    # headings
    assert has_element?(lv, "h3", "Users")
    assert has_element?(lv, "p", "#{@number_of_records + 1} records found")
    assert page_title(lv) =~ "Users"

    # table header
    for field <- LiveUI.index_view(%User{})[:fields],
        do: assert(has_element?(lv, "th", Phoenix.Naming.humanize(field)))

    # user on first page
    assert has_element?(lv, "td", first_user.name)

    # table row with first_user
    not_formatted_fields =
      LiveUI.index_view(first_user)[:fields] --
        (LiveUI.index_view(first_user)[:formatters] |> Keyword.keys())

    for field <- not_formatted_fields,
        LiveUI.Utils.field_type(first_user, field) in [:string, :integer] do
      assert has_element?(lv, "td > div", Map.get(first_user, field))
    end

    # formatted fields
    assert has_element?(lv, "td > div > a[href*=#{first_user.website}]", "Web")

    # relations
    assert has_element?(lv, "td", department.name)
    assert has_element?(lv, "td", company.name)

    # go to next page
    lv |> element("a[href*=#{users_path}/2]", "2") |> render_click()

    # user on second page
    assert has_element?(lv, "td", last_user.name)
    assert has_element?(lv, "td", last_user.email)
    refute has_element?(lv, "td", department.name)

    # go back to first page
    lv |> element("a[href*=#{users_path}]", "1") |> render_click()

    # open search form
    lv |> element("a", "Search") |> render_click()
    refute has_element?(lv, "a[href*=#{users_path}/2]", "2")

    for field <- Flop.Schema.filterable(first_user) do
      assert has_element?(lv, "#users-filters form label", Phoenix.Naming.humanize(field))
      assert has_element?(lv, "input[value=#{field}]")
    end

    # find single user
    html =
      lv
      |> element("[phx-change=users-update-filter]")
      |> render_change(%{"filters" => %{"0" => %{"field" => "name", "value" => last_user.name}}})

    assert has_element?(lv, "p", "1 records found")
    assert has_element?(lv, "td", last_user.name)
    refute html =~ "Next"
  end
end
