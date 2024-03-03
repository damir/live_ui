defmodule LiveUI.Config.LiveSelect do
  @moduledoc """
  LiveSelect configuration.
  """

  @css_opts [
    container_class: "relative h-full",
    text_input_class: "pc-text-input",
    dropdown_class: [
      "mt-1 w-full absolute cursor-pointer z-50 rounded-md border border-gray-300 bg-white",
      "dark:bg-gray-800 dark:border-gray-600"
    ],
    option_class: [
      "m-1 px-4 py-1 text-gray-700 bg-gray-100 rounded hover:bg-gray-200",
      "dark:text-gray-300 dark:bg-gray-600 hover:dark:bg-gray-700"
    ],
    clear_button_class: "text-gray-500",
    text_input_selected_class: "",
    active_option_class: ""
  ]

  def css_opts(), do: Application.get_env(:live_ui, :live_select_css_opts) || @css_opts
end
