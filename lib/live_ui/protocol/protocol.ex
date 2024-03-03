defmodule LiveUI.Protocol do
  @moduledoc """
  Default implementation for `LiveUI` protocol.
  """

  @doc false
  defmacro __using__(opts) do
    quote location: :keep do
      require Protocol
      import LiveUI.Protocol.Utils

      @ignored_fields Application.compile_env(:live_ui, :ignored_fields) || []
      @fields @for.__schema__(:fields) -- @ignored_fields

      # derive flop protocol
      if flop_opts = unquote(opts[:flop]) do
        Protocol.derive(Flop.Schema, @for, flop_opts)
      else
        sort_field = if :updated_at in @fields, do: :updated_at, else: :id

        if Flop.Schema.impl_for(struct(@for)) == Flop.Schema.Any do
          Protocol.derive(Flop.Schema, @for,
            filterable: @fields,
            sortable: [sort_field],
            default_order: %{order_by: [sort_field], order_directions: [:desc]}
          )
        end
      end

      @fields_by_type Enum.group_by(@fields, fn field ->
                        LiveUI.Utils.field_type(struct(@for), field)
                      end)
                      |> Keyword.new()

      @title_field Enum.at(@fields_by_type[:string], 0)
      @description_field Enum.at(@fields_by_type[:string], 1)
      @modules Module.split(@for)
      @namespace_module if length(@modules) > 2, do: Enum.at(@modules, 1)
      @namespace if @namespace_module, do: @namespace_module |> Macro.underscore()
      @resource @modules |> List.last() |> Macro.underscore()
      @resources @resource <> "s"

      @belongs_to_fields for association <- @for.__schema__(:associations),
                             relation = @for.__schema__(:association, association),
                             match?(%Ecto.Association.BelongsTo{}, relation),
                             do: relation.owner_key

      @parent_relations (for association <- @for.__schema__(:associations),
                             relation = @for.__schema__(:association, association),
                             relation.relationship == :parent,
                             relation.owner_key not in @ignored_fields,
                             reduce: [] do
                           relations ->
                             Keyword.put(
                               relations,
                               relation.owner_key,
                               name: association,
                               owner_key: relation.owner_key,
                               relationship: relation.relationship,
                               search_field_for_title:
                                 LiveUI.search_field_for_title(struct(relation.related)),
                               schema_module: relation.queryable
                             )
                         end)

      @parent_relation_names (for {_field, relation} <- @parent_relations, reduce: [] do
                                parent_relation_names -> [relation[:name] | parent_relation_names]
                              end)

      @non_editable_fields [:id, :inserted_at, :updated_at]
      @editable_fields @fields -- @non_editable_fields

      # defaults
      def title(record), do: Map.get(record, @title_field)
      def description(record), do: Map.get(record, @description_field)
      def heading(_), do: false
      def namespace(_), do: @namespace
      def resource(_), do: @resource
      def resources(_), do: @resources
      def ignored_fields(_), do: []
      def search_field_for_title(_), do: @title_field
      def search_field_for_description(_), do: @description_field
      def search_function(_), do: false
      def filter_operators(_), do: []
      def input_hints(_), do: []
      def ownership(_), do: false
      def uploads(_), do: []

      # configurable with utils
      def index_view(record) do
        [
          actions: [
            new: [
              name: "New #{@resource}",
              allowed: true,
              fields: @editable_fields -- ignored_fields(record),
              optional_fields: [],
              inputs: [],
              function: &LiveUI.Queries.create/2,
              changeset: &LiveUI.Changeset.create_changeset/3,
              validate_changeset: &LiveUI.Changeset.create_changeset/3
            ]
          ],
          batch_actions: [
            delete: [name: "Delete", allowed: true, function: &LiveUI.Queries.delete_ids/2]
          ],
          fields: @fields -- ignored_fields(record),
          preload: @parent_relation_names,
          function: &LiveUI.Queries.find_by_filter/3,
          formatters: []
        ]
      end

      def show_view(record) do
        [
          actions: [
            edit: [
              name: "Edit",
              allowed: true,
              fields: @editable_fields -- ignored_fields(record),
              optional_fields: [],
              inputs: [],
              function: &LiveUI.Queries.update/2,
              changeset: &LiveUI.Changeset.update_changeset/3,
              validate_changeset: &LiveUI.Changeset.update_changeset/3
            ],
            delete: [name: "Delete", allowed: true, function: &LiveUI.Queries.delete/2]
          ],
          fields: @fields -- ignored_fields(record),
          preload: @parent_relation_names,
          function: &LiveUI.Queries.find_by_id/2,
          formatters: []
        ]
      end

      # allow overrides for above functions
      defoverridable Module.definitions_in(__MODULE__, :def)

      # static internals
      def parent_relations(_), do: @parent_relations
      def fields_by_type(_), do: @fields_by_type

      # build an atom to avoid not existing atom error
      _ = String.to_atom(@resource)
    end
  end
end

defprotocol LiveUI do
  @moduledoc ~S'''
  Protocol for `Ecto.Schema` struct to configure related `Phoenix.LiveView` modules.

  ## Simple setup

      defimpl LiveUI, for: MyApp.Admin.Company do
        use LiveUI.Protocol
      end

  Calling `use LiveUI.Protocol` will define all function which are implementing the `LiveUI` protocol.
  It is a convenience to eliminate the boilerplate code required by the protocol. Most of the values set
  by the macro are the ones you would expect, like using the first string field as a title or building
  relation links using foreign keys. When that is not the case, we can override these functions to change
  how the data will be presented and processed.

  ## Custom setup

      defimpl LiveUI, for: MyApp.Admin.User do
        use LiveUI.Protocol,
          flop: [
            filterable: [:name, :email, :activated_at],
            sortable: [:activated_at],
            default_order: %{order_by: [:activated_at], order_directions: [:desc]}
          ]

        def title(user), do: record.name
        def description(user), do: user.email
        def filter_operators(_), do: [age: [:<=, :>=]]
        def input_hints(_), do: [website: "Should begin with https://"]
        def uploads(_), do: [image: [accept: ~w(.jpg .jpeg),max_file_size: 800_000]]

        def index_view(user) do
          super(user)
          |> ignore_fields(:new, [:confirmed_at])
          |> add_batch_action(:deactivate, "Deactivate", MyAppWeb.Admin.UserLive.Deactivate)
          |> add_formatters(website: {&link_/1, %{name: "Web"}})
        end

        def show_view(user) do
          super(user)
          |> add_formatters(bio: &markdown/1, website: &link_/1)
        end
      end

  NOTE: `flop` option will derive `Flop.Schema` protocol unless it is already derived in Ecto schema module:

      Protocol.derive(Flop.Schema, MyApp.Admin.User,
        filterable: <all schema fields>,
        sortable: [<:updated_at or :id>],
        default_order: %{order_by: [<:updated_at or :id>], order_directions: [:desc]}
      )

  `:updated_at` is the only sort filed set with a fallback to `:id` if it doesn't exist.
  Also, all fields are searchable by default. Please check `Flop.Schema` for more info.


  ## Extending live view modules

  Customizing default views via protocol is sometimes not enough as we might need extra markup and logic in these views.

  Default template can be extended by overriding `c:Phoenix.LiveView.render/1` callback. We could do the same
  with `c:Phoenix.LiveView.mount/3` if we need to put extra assigns into socket. Finally, the data
  could be processed with custom `c:Phoenix.LiveView.handle_event/3` callbacks.

      defmodule LiveUIWeb.Admin.UserLive.Index do
        use LiveUI.Views.Index, for: LiveUI.Admin.User

        def mount(params, session, socket) do
          {:ok, socket} = super(params, session, socket)
          {:ok, socket |> assign(:greeting, "Hello")}
        end

        def render(assigns) do
          ~H"""
          <.p phx-click="bigger-greeting"><%= @greeting %> from extra markup before the table!</.p>
          <%= super(assigns) %>
          """
        end

        def handle_event("bigger-greeting", _, socket) do
          {:noreply, socket |> assign(greeting: String.upcase(socket.assigns.greeting))}
        end
      end
  '''

  @fallback_to_any true

  @doc """
  Defines a title for the record, it is set as page title and used in HEEX templates.

  Default is the value of the first string field from the Ecto struct.

      # custom field
      def title(user), do: record.name

      # computed value
      def title(user), do: "\#{user.first_name} \#{user.last_name}"
  """
  def title(record)

  @doc """
  Defines a description for the record, it is used in HEEX templates.

  Default implementation is the value of the second string field from the Ecto struct.
  """
  def description(record)

  @doc ~S'''
  Renders `Show` page heading as a component instead of `title/1`.

  Default implementation is `false` which will prevent it from rendering.

  ## Example

      use Phoenix.Component
      import LiveUI.Components.Core

      def heading(assigns) do
        ~H"""
        <.h3><%= @name %></.h3>
        <.p><%= @email %></.p>
        """
      end

  NOTE: `p` and `h3` components are from `LiveUI.Components.Core` which delegates the calls to `PetalComponents`.
  '''
  def heading(record)

  @doc """
  Name of the parent namespace for nested routes.

  Default is the name of second to last module of the Ecto struct.
  For example, `MyApp.Admin.User` will produce routes starting with `/admin/users`.
  """
  def namespace(record)

  @doc """
  Resource name that is used in routes and templates.

  Default is the name of the last module of the Ecto struct.
  """
  def resource(record)

  @doc """
  Resource name in plural that is used in routes and templates.

  Default is the name of the last module of the Ecto struct with appended `s` character.
  This should be overriden for plurals like `companies` or `fish`.
  """
  def resources(record)

  @doc """
  List of ignored fields, it is applied to both `Index` and `Show` views and their forms.

  NOTE: fields can be also ignored for all schema modules via application config:

        config :live_ui,
          ignored_fields: [:token, :first_version_id, :current_version_id]
  """
  def ignored_fields(record)

  @doc """
  The field name selected in query which value is shown in `LiveSelect` dropdown list as record title.

  Default is the title field.
  """
  def search_field_for_title(record)

  @doc """
  The field name selected in query which value is shown in `LiveSelect` dropdown list as record description.

  Default is the description field.
  """
  def search_field_for_description(record)

  @doc """
  Search function used by `LiveSelect` to search for parent records in forms.

  It uses configured `search_field_for_title/1` and `search_field_for_description/1` fields in select statement.

  Default implementation will scope the result to current user from the socket assign if configured via `ownership/1`.
  It will also apply the scope of selected parent to other relations if they share the same parent as the record
  being created, ie. when selecting a company with one LiveSelect input only departments from that company will be
  searched in second LiveSelect input.

  Custom function accepts socket assigns and search term and should return a map with id, label and description
  fields used in `LiveSelect` dropdown list.

      def search_function(_department), do: &search_by_name/2

      # scope department search to current user's company
      def search_by_name(assigns, text) do
        import Ecto.Query
        company_id = Map.get(assigns[:current_user], :company_id)
        ilike = "\#{text}%"

        from(d in MyApp.Department,
          where: [company_id: ^company_id],
          where: ilike(d.name, ^ilike),
          select: %{
            value: d.id,
            label: d.name,
            description: d.location
          },
          limit: 5
        )
        |> LiveUI.Repo.all()
      end

  Default implementation will apply the same scope to `:company_id` since `User` and `Department`
  schemas have the same `belongs_to :company` relation.
  """
  def search_function(record)

  @doc """
  Configures `t:Flop.Filter.op/0` operators for fields in search form.

  Default operator for string fields is `:ilike`, for numbers and dates it is `:==`.

  ## Example

      # add extra inputs to search form
      def filter_operators(_user), do: [age: [:<=, :>=]]

  NOTE: This setting is not applicable to boolean and enum fields; they are always rendered as drop-down list.
  Also, any searchable foreign key field is rendered as `LiveSelect` component.
  """
  def filter_operators(record)

  @doc """
  Add input_hints to form inputs.

  ## Example

      def input_hints(_user), do: [website: "Should begin with https://"]
  """
  def input_hints(record)

  @doc """
  Configures ownership relation for database queries, default is false.

  This will scope queries to `:user_id` foreign key that is equal to `:id` key of the `:current_user` socket assign:

      def ownership(_contact), do: {:user_id, :current_user}
  """
  def ownership(record)

  @doc """
  Configures upload fields. For single file upload use `Ecto` string type; for multiple files use array of strings.

  ## Examples

      def uploads(_) do
        [
          # ecto string
          image: [
            accept: ~w(.jpg .jpeg),
            max_file_size: 800_000
          ],
          # ecto array of strings
          extra_images: [
            accept: ~w(.jpg .jpeg),
            max_entries: 3,
            max_file_size: 800_000
          ]
        ]
      end

  In case of local upload, files are saved using `priv/static/uploads/<resource>/<field>/<uuid>-<file-name> path`,
  path for `image` field in `product` schema might look like this:

      priv/static/uploads/product/image/1a64228b-54a4-4824-a90f-b236806aecbb-elixir.jpg

  which is served from this url:

      http://localhost:4010/uploads/product/image/1a64228b-54a4-4824-a90f-b236806aecbb-elixir.jpg

  ## Configure static path and live reloader

  To enable serving from `uploads` folder add it to the `static_paths` list in `my_app_web.ex`:

      def static_paths, do: ~w(assets fonts images favicon.ico robots.txt uploads)

  In `dev.ex` disable live reload when files are added to `uploads` folder:

      ~r"priv/static/(?!uploads).*(js|css|png|jpeg|jpg|gif|svg)$"
  """
  def uploads(record)

  @doc """
  Configuration that controls how the data is displayed in the table and how is processed with create form.
  It also holds an info about custom actions, ie. `Deactivate` action in the example.

      # LiveUI.index_view(%User{})
      [
        formatters: [website: {&LiveUI.Formatters.link_/1, %{name: "Web"}}],
        actions: [
          new: [
            name: "New user",
            allowed: true,
            fields: [:name, :email, :bio, :age, :website, :company_id, :department_id, :role, :active],
            optional_fields: [:age],
            inputs: [],
            function: &LiveUI.Queries.create/2,
            changeset: &LiveUI.Changeset.create_changeset/3,
            validate_changeset: &LiveUI.Changeset.create_changeset/3
          ]
        ],
        batch_actions: [
          deactivate: [
            name: "Deactivate",
            component: LiveUIWeb.Admin.UserLive.Deactivate
          ],
          delete: [
            name: "Delete",
            allowed: true,
            function: &LiveUI.Queries.delete_ids/2
          ]
        ],
        fields: [:id, :name, :email, :website, :company_id, :department_id, :role, :active, :confirmed_at],
        preload: [:company, :department],
        function: &LiveUI.Queries.find_by_filter/3
      ]

  This structure can be updated directly or by using built-in functions from `LiveUI.Protocol.Utils`.

  Use `put_in/3` function:

      # disable update form
      def show_view(session) do
        super(session)
        |> put_in([:actions, :edit, :allowed], false)
      end

      # override changeset function for create form
      def index_view(contact) do
        super(contact)
        |> put_in([:actions, :new, :changeset], &MyApp.Member.Contact.create_changeset/3)
      end

      # create_changeset in my_app/member/contact.ex
      def create_changeset(contact, params, socket) do
        LiveUI.Changeset.create_changeset(contact, params, socket)
        |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
      end

  Use `LiveUI.Protocol.Utils.ignore_fields/2` helper function:

      def index_view(user) do
        super(user)
        |> ignore_fields([:updated_at, :inserted_at])
      end

  ## Formatters

  List of formatters to control how the fields are displayed on the screen.
  They are added with `LiveUI.Protocol.Utils.add_formatters/2`.

  ## Actions

  Built-in and custom actions are rendered inside the modal.
  Custom actions are added with `LiveUI.Protocol.Utils.add_action/5`.

  ### New action

  Built-in action that renders a form to create records.

  - name

    Used as text in action button and page title.

  - allowed

    Boolean or a function to allow access to the action.
    The function accepts socket assign and should return a boolean.

  - fields

    List of fields which are rendered in the form.
    All fields are included unless ignored with `LiveUI.Protocol.Utils.ignore_fields/3`.

  - optional_fields

    All fields are required unless they are set as optional with `LiveUI.Protocol.Utils.set_optional_fields/3`.

  - inputs

    Configures form input types via `LiveUI.Protocol.Utils.configure_inputs/3`.

  - function

    Function that saves the record. Override if extra logic is needed.

  - changeset

    Changeset function for phx-submit that validates all fields as required.
    Override to add custom validation.

  - validate_changeset

    Changeset function for phx-change that points to changset for phx-submit by default.
    Override if it behaves differently.

  ## Batch actions

  Built-in and custom batch actions are rendered inside the modal and they operate on selected records.
  Custom batch actions are added with `LiveUI.Protocol.Utils.add_batch_action/5`.

  ### Delete action

  Built-in batch action that renders a dialog to delete selected records.

  - name

    Used as text in action button and page title.

  - allowed

    Boolean or a function to allow access to the action.
    The function accepts socket assign and should return a boolean.

  - function

    Function that deletes selected records. Override if extra logic is needed.

  ## Fields

  List of fields to display in the table. Defaults to all fields.
  Fields could be removed from the list with `LiveUI.Protocol.Utils.ignore_fields/2`.

  ## Preload

  List of parent relation that are preloaded and shown in the table with links to their own `Show` view.
  Defaults to all `belongs_to` relations.

  ## Function

  Function that loads the records which are filtered with `Flop.Filter` via search form.
  It will scope the result to current user if configured with `ownership/1`
  """
  def index_view(record)

  @doc """
  Configuration that controls how the data is displayed for a single record and how is processed with edit form.
  The fields are documented in `LiveUI.index_view/1`.

      # LiveUI.show_view(%User{})
      [
        formatters: [
          email: &LiveUI.Formatters.copy/1,
          bio: &LiveUI.Formatters.markdown/1,
          website: &LiveUI.Formatters.link_/1,
          role: &String.upcase/1
        ],
        actions: [
          edit: [
            name: "Edit",
            allowed: true,
            fields: [:name, :email, :bio, :age, :website, :company_id, :department_id, :role, :active, :confirmed_at],
            optional_fields: [],
            inputs: [],
            function: &LiveUI.Queries.update/2,
            changeset: &LiveUI.Changeset.update_changeset/3,
            validate_changeset: &LiveUI.Changeset.update_changeset/3
          ],
          delete: [
            name: "Delete",
            allowed: true,
            function: &LiveUI.Queries.delete/2
          ]
        ],
        fields: [:id, :name, :email, :bio, :age, :website, :company_id, :department_id, :role, :active, :confirmed_at, :inserted_at, :updated_at],
        preload: [:company, :department],
        function: &LiveUI.Queries.find_by_id/2
      ]
  """
  def show_view(record)

  @doc false
  def parent_relations(record)

  @doc false
  def fields_by_type(record)
end

# minimal implementations that should not break HEEX templates
# NOTE: we cannot `use LiveUI.Protocol` with Any
defimpl LiveUI, for: Any do
  def title(%Ecto.Association.NotLoaded{}), do: Ecto.Association.NotLoaded
  def title(record), do: Map.get(record, search_field_for_title(record))
  def resources(record), do: Module.split(record.__struct__) |> List.last() |> Macro.underscore()
  def heading(_), do: false

  def search_field_for_title(record) do
    mod = record.__struct__
    Enum.find(mod.__schema__(:fields), &(mod.__schema__(:type, &1) not in [:id, :binary]))
  end

  # empty fields
  for fun <- [
        :uploads,
        :input_hints,
        :index_view,
        :show_view,
        :parent_relations,
        :fields_by_type,
        :ignored_fields
      ],
      do: def(unquote(fun)(_), do: [])

  # these will not break template
  for fun <- [
        :description,
        :filter_operators,
        :namespace,
        :ownership,
        :resource,
        :search_field_for_description,
        :search_function
      ],
      do: def(unquote(fun)(_any), do: nil)
end
