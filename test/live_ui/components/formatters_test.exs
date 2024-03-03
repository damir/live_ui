defmodule LiveUI.FormattersTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import LiveUI.Formatters

  test "mask" do
    assert mask(:non_binary) == :non_binary

    for {value, opts, expected} <- [
          {"1234567890", [], String.duplicate("*", 12)},
          {"1234567890", [left: 4], "****567890"},
          {"1234567890", [right: 4], "123456****"},
          {"1234567890", [left: 4, right: 4], "****56****"},
          {"12345678", [left: 4, right: 4], "********"},
          {"1234", [left: 4, right: 4], "********"},
          {"12", [left: 4, right: 4], "********"}
        ] do
      assert mask(value, opts) == expected
    end
  end

  test "link_" do
    name = "A link"
    value = "http://example.com"

    icon_html =
      "\n  <span class=\"hero-arrow-top-right-on-square-mini w-4 h-4 text-gray-400\"></span>\n"

    assert render_component(&link_/1, value: nil) ==
             ~s(<a href="" target=\"_blank\">\n  #{icon_html}</a>)

    assert render_component(&link_/1, value: value) ==
             ~s(<a href="#{value}" target=\"_blank\">\n  #{value}#{icon_html}</a>)

    assert render_component(&link_/1, value: value, name: name) ==
             ~s(<a href="#{value}" target=\"_blank\">\n  #{name}#{icon_html}</a>)
  end
end
