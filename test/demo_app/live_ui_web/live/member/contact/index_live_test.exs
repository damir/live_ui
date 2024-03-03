defmodule LiveUIWeb.Member.Contact.IndexLiveTest do
  use LiveUIWeb.ConnCase
  import Phoenix.LiveViewTest
  alias LiveUI.Member.Contact
  alias LiveUI.Repo

  @number_of_records 15

  test "list and search records", %{conn: conn} do
    me = LiveUI.AccountsFixtures.user_fixture()

    my_contacts =
      for n <- 1..@number_of_records do
        %Contact{
          name: "name-#{n}",
          email: "email",
          phone: "123",
          user_id: me.id,
          # default order is by updated_at
          updated_at:
            NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.add(n)
        }
        |> Repo.insert!()
      end

    their_contact = %Contact{name: "name", email: "email", phone: "123"} |> Repo.insert!()

    {:ok, lv, _html} = live(_conn = log_in_user(conn, me), contacts_path = ~p"/member/contacts")

    # headings
    assert has_element?(lv, "h3", "Contacts")
    assert has_element?(lv, "p", "#{@number_of_records} records found")
    assert page_title(lv) =~ "Contacts"

    # table header
    for field <- LiveUI.index_view(%Contact{})[:fields],
        do: assert(has_element?(lv, "th", Phoenix.Naming.humanize(field)))

    my_first_contact = List.first(my_contacts)
    my_last_contact = List.last(my_contacts)

    # contact on first page
    assert has_element?(lv, "td", my_last_contact.name)

    # go to next page
    lv |> element("a[href*=#{contacts_path}/2]", "2") |> render_click()

    # contact on second page
    assert has_element?(lv, "td", my_first_contact.name)

    # go back to first page
    lv |> element("a[href*=#{contacts_path}]", "1") |> render_click()

    # search form
    lv |> element("a", "Search") |> render_click()

    for field <- Flop.Schema.filterable(my_first_contact) do
      assert has_element?(lv, "#contacts-filters form label", Phoenix.Naming.humanize(field))
      assert has_element?(lv, "input[value=#{field}]")
    end

    # find my contact
    html =
      lv
      |> element("[phx-change=contacts-update-filter]")
      |> render_change(%{"filters" => %{"0" => %{"field" => "id", "value" => my_last_contact.id}}})

    assert has_element?(lv, "p", "1 records found")
    assert has_element?(lv, "td", my_last_contact.name)
    refute html =~ "Next"

    # fail to find their contact
    lv
    |> element("[phx-change=contacts-update-filter]")
    |> render_change(%{"filters" => %{"0" => %{"field" => "id", "value" => their_contact.id}}})

    refute has_element?(lv, "td", their_contact.name)
    assert has_element?(lv, "div", "No records found.")

    # custom action
    element(lv, "a", "Get api key") |> render_click()
    assert has_element?(lv, "p", "Use this key")
    assert page_title(lv) =~ "Get api key"
    assert_patched(lv, "#{contacts_path}/api_key")
    element(lv, "a[href*=#{contacts_path}]", "Back") |> render_click()
  end
end
