defmodule LiveUI.Components.Field do
  @moduledoc """
  Formatting field values.
  """

  use Phoenix.Component
  import LiveUI.Components.Core
  import LiveUI.Utils

  attr :record, :map, required: true
  attr :field, :atom, required: true
  attr :formatter, :any, default: false
  attr :action, :atom, default: :index

  def render(assigns) do
    value = Map.get(assigns.record, assigns.field)
    assigns = assign(assigns, :value, value)

    if assigns.formatter do
      if is_nil(value) do
        empty(%{})
      else
        ~H"""
        <%= render_formatted_field(@record, @field, @value, @formatter) %>
        """
      end
    else
      ~H"""
      <%= render_field(@record, @field, @value, @action) %>
      """
    end
  end

  defp not_set(assigns), do: ~H"&lt;not set&gt;"
  defp empty(assigns), do: ~H"&lt;empty&gt;"

  defp render_field(record, field, value, action) do
    case field_type(record, field) do
      :id ->
        render_id_field(record, field, value, action)

      type ->
        case type do
          :string -> render_string_field(record, field, value)
          :array -> render_array_field(record, field, value)
          type -> render_field(type, value)
        end
    end
  end

  defp render_id_field(_record, _field, nil, _action), do: not_set(%{})

  defp render_id_field(record, field, value, action) do
    if field == :id do
      value
    else
      relation = record |> LiveUI.parent_relations() |> Keyword.get(field)
      relation_record = record |> Map.get(relation[:name])

      # link or text for inline edit
      if action == :index do
        relation_link(%{record: relation_record})
      else
        LiveUI.title(relation_record)
      end
    end
  end

  def render_array_field(record, field, value) do
    if upload_config = LiveUI.uploads(record)[field] do
      if image_field?(upload_config[:accept]) do
        render_images(%{srcs: value, alt: field})
      else
        render_files(%{hrefs: value})
      end
    else
      render_list(%{value: value})
    end
  end

  def render_string_field(record, field, value) do
    if upload_config = LiveUI.uploads(record)[field] do
      if image_field?(upload_config[:accept]) do
        render_image(%{src: value, alt: field})
      else
        render_file(%{href: value})
      end
    else
      render_field(:string, value)
    end
  end

  attr :srcs, :list
  attr :alt, :string
  attr :wrapper_class, :string, default: "gap-2"
  attr :image_class, :string, default: "size-12"
  attr :placeholder_class, :string, default: "size-12"

  def render_images(%{srcs: []} = assigns) do
    ~H"""
    <.render_image src={nil} placeholder_class={@placeholder_class} />
    """
  end

  def render_images(assigns) do
    ~H"""
    <div class={[@wrapper_class, "flex flex-wrap justify-start"]}>
      <.render_image
        :for={{src, i} <- Enum.with_index(@srcs, 1)}
        src={src}
        alt={"#{@alt}-#{i}"}
        class={@image_class}
      />
    </div>
    """
  end

  attr :src, :any
  attr :alt, :string
  attr :class, :string, default: "size-12"
  attr :placeholder_class, :string, default: "size-12"

  def render_image(%{src: nil} = assigns) do
    ~H"""
    <div class={[@placeholder_class, "flex items-center justify-center border drop-shadow rounded-md"]}>
      <.icon name="hero-photo" class="size-1/2 text-gray-400" />
    </div>
    """
  end

  def render_image(assigns) do
    ~H"""
    <a href={@src} target="_">
      <img src={@src} alt={@alt} class={[@class, "object-cover drop-shadow rounded-md"]} />
    </a>
    """
  end

  attr :hrefs, :list

  def render_files(%{hrefs: []} = assigns), do: not_set(assigns)

  def render_files(assigns) do
    ~H"""
    <.ul>
      <li :for={href <- @hrefs}><.render_file href={href} /></li>
    </.ul>
    """
  end

  attr :href, :string

  def render_file(%{href: nil} = assigns), do: not_set(assigns)

  def render_file(assigns) do
    ~H"""
    <a href={@href} target="_">
      <%= @href |> String.split("/") |> List.last() %>
    </a>
    """
  end

  # nil/empty value
  def render_field(_type, nil), do: not_set(%{})
  def render_field(_type, ""), do: empty(%{})

  # simple values
  for type <- [:string, :integer, :float, :decimal],
      do: def(render_field(unquote(type), value), do: value)

  # time/date values
  for type <- [:date, :utc_datetime, :naive_datetime],
      do: def(render_field(unquote(type), value), do: localized_date(value))

  def render_field(:enum, value), do: Phoenix.Naming.humanize(value)

  def render_field(:binary, value), do: "<binary (#{byte_size(value)} bytes)>"

  def render_field(:boolean, true), do: render_boolean(%{value: true})

  def render_field(:boolean, false), do: render_boolean(%{value: false})

  def render_field(:array, value), do: render_list(%{value: value})

  def render_field(:map, value), do: render_map(%{value: value})

  def render_field(type, value), do: "<#{type}> " <> inspect(value)

  def render_boolean(%{value: true} = assigns) do
    ~H"""
    <.badge color="success" label="Yes" size="lg" variant="outline" class="w-10" />
    """
  end

  def render_boolean(%{value: false} = assigns) do
    ~H"""
    <.badge color="danger" label="No" size="lg" variant="outline" class="w-10" />
    """
  end

  def render_list(%{value: []} = assigns), do: not_set(assigns)

  def render_list(assigns) do
    ~H"""
    <.badge :for={item <- @value} label={item} color="gray" variant="outline" class="mr-1" />
    """
  end

  def render_map(assigns) do
    ~H"""
    <pre><%= Jason.encode!(@value, pretty: true) %></pre>
    """
  end

  # multiple formatters
  defp render_formatted_field(record, field, value, formatters) when is_list(formatters) do
    for formatter <- formatters, reduce: value do
      acc -> render_formatted_field(record, field, acc, formatter)
    end
  end

  # css class formatter
  defp render_formatted_field(_record, _field, value, formatter) when is_binary(formatter),
    do: PhoenixHTMLHelpers.Tag.content_tag(:span, value, class: formatter)

  # component or function formatter with options
  defp render_formatted_field(record, field, value, {formatter, opts}) do
    case opts do
      %{} ->
        formatter.(Map.merge(%{value: value, record: record, field: field}, opts))

      _ ->
        case Function.info(formatter, :arity) do
          {:arity, 2} -> formatter.(value, opts)
          {:arity, 3} -> formatter.(record, value, opts)
        end
    end
  end

  # string function or component formatter
  defp render_formatted_field(record, field, value, formatter) do
    case Function.info(formatter, :module) do
      {:module, String} ->
        formatter.(to_string(value))

      _ ->
        case Function.info(formatter, :arity) do
          {:arity, 1} -> formatter.(%{value: value, record: record, field: field})
          {:arity, 2} -> formatter.(record, value)
        end
    end
  end
end
