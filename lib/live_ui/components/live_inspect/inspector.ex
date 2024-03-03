defmodule LiveInspect.Inspector do
  @moduledoc false

  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, assign(socket, root?: true)}
  end

  def update(%{__toggle_expanded__: true}, socket) do
    {:ok, assign(socket, :expanded?, not socket.assigns.expanded?)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_initial_expanded()}
  end

  def handle_event("toggle-expanded", %{"id" => id}, socket) do
    send_update(__MODULE__, %{id: id, __toggle_expanded__: true})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <%= cond do %>
        <% not @expanded? -> %>
          <div class={term_css_class(@term)}>
            <%= inspect_hidden(@term) %>
          </div>
        <% enumerable?(@term) and not empty?(@term) -> %>
          <%= if is_struct(@term) do %>
            <div class={term_css_class(@term)}>
              <%= inspect_hidden(@term) %>
            </div>
          <% end %>

          <table class="table-auto">
            <%= for {index, key, value} <- enumerate(@term, @opts) do %>
              <tr class="align-top border-b border-gray-300 dark:border-gray-700 dark:bg-gray-800 last:border-0 text-gray-700 dark:text-gray-300 ">
                <td
                  phx-click="toggle-expanded"
                  phx-value-id={nested_id(@id, index)}
                  phx-target={@myself}
                  class={["p-2", if(enumerable?(@term), do: "cursor-pointer")]}
                >
                  <%= if is_integer(key) do %>
                    <span class="text-amber-500"><%= key %></span>
                  <% else %>
                    <%= inspect(key) %>
                  <% end %>
                </td>
                <td class="p-2">
                  <.live_component
                    opts={@opts}
                    id={nested_id(@id, index)}
                    key={key}
                    module={__MODULE__}
                    root?={false}
                    term={value}
                  />
                </td>
              </tr>
            <% end %>
          </table>
        <% :else -> %>
          <div class={term_css_class(@term)}>
            <%= inspect(@term) %>
          </div>
      <% end %>
    </div>
    """
  end

  defp assign_initial_expanded(socket) do
    if changed?(socket, :root?) do
      assign(
        socket,
        :expanded?,
        socket.assigns.root? or short?(socket.assigns.term)
      )
    else
      socket
    end
  end

  defp short?(value) do
    not enumerable?(value) or value == [] or value == %{}
  end

  defp empty?(value) do
    value == [] or value == %{}
  end

  defp enumerable?(value) do
    is_list(value) or is_map(value) or is_tuple(value)
  end

  defp enumerate(tuple, opts) when is_tuple(tuple) do
    enumerate(Tuple.to_list(tuple), opts)
  end

  defp enumerate(list, _opts) when is_list(list) do
    for {value, index} <- Enum.with_index(list), do: {inspect(index), index, value}
  end

  defp enumerate(map, opts) when is_map(map) do
    case opts[:map_keys] do
      :all ->
        for {key, index} <- Enum.with_index(Map.keys(map)),
            key != :__struct__,
            do: {inspect(index), key, Map.fetch!(map, key)}

      _else ->
        for {key, index} <- Enum.with_index(Map.keys(map)),
            not (is_atom(key) and String.starts_with?(to_string(key), "_")),
            do: {inspect(index), key, Map.fetch!(map, key)}
    end
  end

  defp nested_id(id, index) do
    "#{to_string(id)}-#{to_string(index)}"
  end

  defp inspect_hidden([_]), do: "1 item"
  defp inspect_hidden(list) when is_list(list), do: "#{length(list)} items"

  defp inspect_hidden(%struct{} = value)
       when struct in [DateTime, NaiveDateTime, Regex, Range, MapSet],
       do: inspect(value)

  defp inspect_hidden(%struct{}) do
    case to_string(struct) do
      "Elixir." <> module -> "%#{module}{}"
      other -> "%#{other}{}"
    end
  end

  defp inspect_hidden(map) when is_map(map) and map_size(map) == 1, do: "1 field"
  defp inspect_hidden(map) when is_map(map), do: "#{map_size(map)} fields"

  defp inspect_hidden({}), do: "{}"
  defp inspect_hidden(tuple) when is_tuple(tuple), do: "#{tuple_size(tuple)} items"

  defp inspect_hidden(term), do: inspect(term)

  defp term_css_class(number) when is_number(number), do: "text-amber-500"
  defp term_css_class(binary) when is_binary(binary), do: "text-gray-500"
  defp term_css_class(struct) when is_struct(struct), do: "text-blue-500"
  defp term_css_class(map) when is_map(map), do: "text-blue-500"
  defp term_css_class(list) when is_list(list), do: "text-blue-500"
  defp term_css_class(tuple) when is_tuple(tuple), do: "text-blue-500"
  defp term_css_class(true), do: "text-green-700"
  defp term_css_class(false), do: "text-red-700"
  defp term_css_class(atom) when is_atom(atom), do: "text-teal-500"
  defp term_css_class(pid) when is_pid(pid), do: "text-gray-500"
  defp term_css_class(_else), do: ""
end
