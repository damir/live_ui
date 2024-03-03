defmodule LiveUI.Router do
  @moduledoc """
    Macro which defines a set of routes for given `Ecto.Schema` module.
  """

  @doc """
  Helper that generates all required routes for a resource.

      # router.ex
      scope "/", MyAppWeb do
        scope "/admin", Admin do

          # generate all routes
          live_ui("/companies", UserLive, MyApp.Admin.User)

          # or define each one
          live("/users", UserLive.Index, :index)
          live("/users/new", UserLive.Index, :new)
          live("/users/:id", UserLive.Show, :show)
          live("/users/:id/edit", UserLive.Show, :edit)
          live("/users/:id/delete", UserLive.Show, :delete)
        end
      end

  `UserLive.Index` and `UserLive.Show` modules should call the macro to get basic `Phoenix.LiveView` implementation:

      # lib/my_app_web/live/admin/user_live/index.ex
      defmodule MyAppWeb.Admin.UserLive.Index do
        use LiveUI.Views.Index, for: MyApp.Admin.User
      end

      # lib/my_app_web/live/admin/user_live/show.ex
      defmodule MyAppWeb.Admin.UserLive.Index do
        use LiveUI.Views.Show, for: MyApp.Admin.User
      end

  These modules will provide code to display and process data which is customized
  via `LiveUI` protocol.

  `live_ui/3` will also generate routes for any custom action defined via `LiveUI` protocol:

      live("/users/custom", UserLive.Index, :custom)
      live("/users/:id/custom", UserLive.Show, :custom)
  """
  defmacro live_ui(path, live_module, schema_module) do
    schema_module = Macro.expand(schema_module, __CALLER__)
    record = Macro.escape(struct(schema_module))

    quote location: :keep do
      index_view_config = LiveUI.index_view(unquote(record))

      # index actions
      index_actions =
        Keyword.keys(index_view_config[:actions]) ++
          Keyword.keys(index_view_config[:batch_actions])

      live_module = Module.concat(unquote(live_module), Index)
      live(unquote(path), live_module, :index)
      for action <- index_actions, do: live("#{unquote(path)}/#{action}", live_module, action)

      # show actions
      live_module = Module.concat(unquote(live_module), Show)
      live("#{unquote(path)}/:id", live_module, :show)

      for action <- LiveUI.show_view(unquote(record))[:actions] |> Keyword.keys(),
          do: live("#{unquote(path)}/:id/#{action}", live_module, action)
    end
  end
end
