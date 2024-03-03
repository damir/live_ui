defmodule LiveUI.Formatters do
  @moduledoc """
  Functions for controlling how the fields are displayed on the screen.

      import LiveUI.Formatters

      def index_view(user) do
        super(user)
        |> add_formatters(
          email: {&mask/2, [left: 4]},
          bio: &markdown/1,
          website: {&link_/1, %{name: "Web"}},
          role: &String.capitalize/1
        )
      end


  Adding custom formatter is documented in `LiveUI.Protocol.Utils.add_formatters/2`.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import LiveUI.Components.Core

  @doc """
  Masks a value with asterisks.

        def index_view(user) do
          super(user)
          |> add_formatters(email: {&LiveUI.Formatters.mask/2, [right: 4]})
        end
  """
  def mask(value, opts \\ [])

  def mask(value, opts) when is_binary(value) do
    %{left: left, right: right} = Enum.into(opts, %{left: 0, right: 0})

    if left == 0 && right == 0 do
      String.duplicate("*", 12)
    else
      left_size = min(byte_size(value), left)
      <<_head::binary-size(left_size)>> <> rest = value

      rest_size = byte_size(rest)
      middle_size = max(rest_size - right, 0)
      <<middle::binary-size(middle_size), _rest::binary>> = rest

      String.duplicate("*", left) <> middle <> String.duplicate("*", right)
    end
  end

  def mask(value, _opts), do: value

  @doc """
  Renders markdown as HTML.

      def index_view(user) do
        super(user)
        |> bio: &LiveUI.Formatters.markdown/1
      end
  """
  def markdown(assigns), do: assigns.value |> Earmark.as_html!() |> Phoenix.HTML.raw()

  @doc """
  Renders a link with an icon.

      def index_view(user) do
        super(user)
        |> website: &LiveUI.Formatters.link_/1
        |> website: {&LiveUI.Formatters.link_/1, %{name: "Website"}}
      end
  """
  @doc type: :component
  attr :name, :string, default: ""

  def link_(assigns) do
    {_, uri} = to_string(assigns.value) |> URI.new()
    assigns = Map.put(assigns, :uri, uri)

    ~H"""
    <.link href={@uri} target="_blank">
      <%= if byte_size(@name) == 0, do: @uri, else: to_string(@name) %>
      <.icon name="hero-arrow-top-right-on-square-mini" class="w-4 h-4 text-gray-400" />
    </.link>
    """
  end

  @doc """
  Renders a copy icon next to the value.

      def index_view(user) do
        super(user)
        |> add_formatters(email: &LiveUI.Formatters.copy/1,
      end
  """
  @doc type: :component
  attr :value, :string, doc: "field value that will be copied into clipboard"
  attr :field, :string, doc: "field name used as a part of DOM id - `copy-<field>`"
  attr :class, :string, default: nil, doc: "CSS class"

  def copy(assigns) do
    ~H"""
    <span class={@class} id={"copy-#{@field}"}><%= @value %></span>

    <button phx-click={
      JS.dispatch("phx:copy", to: "#copy-#{@field}")
      |> JS.show(to: "#copy-#{@field}-tooltip", display: "inline")
    }>
      <.icon name="hero-clipboard-document" class="cursor-pointer text-sky-600" />
    </button>

    <.badge color="gray" label="Copied!" class="hidden" id={"copy-#{@field}-tooltip"} />
    """
  end
end
