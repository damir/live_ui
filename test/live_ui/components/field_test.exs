defmodule LiveUI.Components.FieldTest do
  use LiveUI.DataCase
  use Phoenix.Component
  alias LiveUI.Components.Field
  import Phoenix.LiveViewTest

  describe "LiveUI.Components.Field.render without formatters" do
    setup do
      %{record: %LiveUI.Admin.User{name: "John", email: "email", bio: "", age: 22}}
    end

    @tag :capture_log
    test "field is not set", %{record: record} do
      assert render_component(&Field.render/1, record: record, field: :website) ==
               "&lt;not set&gt;"
    end

    test "field is empty string", %{record: record} do
      assert render_component(&Field.render/1, record: record, field: :bio) == "&lt;empty&gt;"
    end

    test "should just render values", %{record: record} do
      assert render_component(&Field.render/1, record: record, field: :name) == record.name

      assert render_component(&Field.render/1, record: record, field: :age) ==
               record.age |> Integer.to_string()
    end

    # TODO: add tests for other ecto types - id, datetime, boolean, enum, binary ...
  end

  describe "LiveUI.Components.Field.render with formatters" do
    test "should format field with with css class" do
      assert render_component(&Field.render/1,
               record: %{abc: "def"},
               field: :abc,
               formatter: "some-css-class"
             ) ==
               "<span class=\"some-css-class\">def</span>"
    end

    test "should format field with String function" do
      assert render_component(&Field.render/1,
               record: %{abc: "def"},
               field: :abc,
               formatter: &String.upcase/1
             ) == "DEF"
    end

    test "should format field with multiple String functions" do
      assert render_component(&Field.render/1,
               record: %{abc: "def"},
               field: :abc,
               formatter: [&String.upcase/1, &String.reverse/1]
             ) == "FED"
    end

    test "should format field with &function/1" do
      assert render_component(&Field.render/1,
               record: %{amount: "12.34"},
               field: :amount,
               formatter: &formatter_function/1
             ) == "USD 12.34"
    end

    defp formatter_function(assigns) do
      "USD #{assigns.value}"
    end

    test "should format field with &function/2" do
      assert render_component(&Field.render/1,
               record: %{amount: 1234, currency: "USD"},
               field: :amount,
               formatter: &formatter_function/2
             ) == "USD 12.34"
    end

    defp formatter_function(record, value) do
      "#{record.currency} #{value / 100}"
    end

    test "should format field with component" do
      assert render_component(&Field.render/1,
               record: %{amount: 1234, currency: "USD"},
               field: :amount,
               formatter: &formatter_component/1
             ) == "USD 12.34"
    end

    defp formatter_component(assigns) do
      ~H"""
      <%= "#{assigns.record.currency} #{assigns.value / 100}" %>
      """
    end
  end
end
