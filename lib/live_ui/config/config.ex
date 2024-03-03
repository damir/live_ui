defmodule LiveUI.Config do
  @moduledoc """
  Generates a config for `Show` and `Index` live components.
  """

  # configured modules from the host app
  def debug, do: Application.get_env(:live_ui, :debug)
  def cldr, do: Application.get_env(:live_ui, :cldr)
  def repo, do: Application.get_env(:live_ui, :repo)

  def repo(schema_module),
    do: if(schema_module.__schema__(:association, :current_version), do: PaperTrail, else: repo())

  # TODO: remove petal dependency
  def error_translator_function,
    do: Application.get_env(:petal_components, :error_translator_function)

  # static configuration
  def new(live_module, schema_module) do
    record = struct(schema_module)

    %{
      # modules
      schema_module: schema_module,
      live_module: live_module,
      web_module: live_module |> Module.split() |> List.first() |> Module.concat(nil),
      form_module: Module.concat(schema_module, Form),

      # names
      index_path: Path.join(["/", LiveUI.namespace(record) || "", LiveUI.resources(record)]),
      namespace: LiveUI.namespace(record),
      resource: LiveUI.resource(record),
      resources: LiveUI.resources(record),

      # relations
      ownership: LiveUI.ownership(record),
      parent_relations: LiveUI.parent_relations(record),

      # NOTE: uploads is reserved assign
      uploads_opts: LiveUI.uploads(record),

      # live views
      index_view: LiveUI.index_view(record),
      show_view: LiveUI.show_view(record),

      # flop
      flop_filters: LiveUI.Config.Flop.filters(record),

      # debug
      debug: debug()
    }
  end
end
