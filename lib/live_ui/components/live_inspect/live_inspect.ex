defmodule LiveInspect do
  @moduledoc """
  Code taken from https://github.com/schrockwell/live_inspect
  """

  use Phoenix.Component

  @spec live_inspect(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def live_inspect(assigns) do
    assigns =
      assigns
      |> assign_new(:id, &default_id/1)
      |> assign_new(:opts, fn -> [] end)

    ~H"""
    <div class="py-1 ring-1 ring-gray-300 rounded dark:ring-gray-700 dark:bg-gray-800">
      <.live_component module={LiveInspect.Inspector} opts={@opts} id={@id} term={@term} />
    </div>
    """
  end

  defp default_id(assigns) do
    case Map.fetch(assigns, :unique) do
      {:ok, suffix} -> "live-inspect-#{suffix}"
      :error -> "live-inspect"
    end
  end
end
