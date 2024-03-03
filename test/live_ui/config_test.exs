defmodule LiveUI.ConfigTest do
  use ExUnit.Case, async: true

  test "config for default protocol" do
    config = LiveUI.Config.new(SomeLiveModule, LiveUI.ConfigTest.User)

    assert %{
             debug: true,
             resource: "user",
             schema_module: LiveUI.ConfigTest.User,
             web_module: SomeLiveModule,
             live_module: SomeLiveModule,
             form_module: LiveUI.ConfigTest.User.Form,
             parent_relations: [],
             ownership: false,
             index_view: [
               actions: [
                 new: [
                   name: "New user",
                   allowed: true,
                   fields: [:name],
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
               fields: [:id, :name],
               preload: [],
               function: &LiveUI.Queries.find_by_filter/3,
               formatters: []
             ],
             show_view: [
               actions: [
                 edit: [
                   name: "Edit",
                   allowed: true,
                   fields: [:name],
                   optional_fields: [],
                   inputs: [],
                   function: &LiveUI.Queries.update/2,
                   changeset: &LiveUI.Changeset.update_changeset/3,
                   validate_changeset: &LiveUI.Changeset.update_changeset/3
                 ],
                 delete: [name: "Delete", allowed: true, function: &LiveUI.Queries.delete/2]
               ],
               fields: [:id, :name],
               preload: [],
               function: &LiveUI.Queries.find_by_id/2,
               formatters: []
             ],
             flop_filters: [id: [type: "number"], name: [type: "text", op: :ilike]],
             namespace: "config_test",
             resources: "users",
             index_path: "/config_test/users",
             uploads_opts: []
           } ==
             config
  end

  test "config for customized protocol" do
    config = LiveUI.Config.new(SomeLiveModule, LiveUI.Admin.User)

    assert %{
             debug: true,
             flop_filters: [
               company_id: [type: "text", relation_field: :company_id],
               department_id: [type: "text", relation_field: :department_id],
               name: [type: "text", op: :ilike],
               email: [type: "text", op: :ilike],
               age: [type: "number"],
               age: [type: "number", op: :>=, label: "Age >="],
               age: [type: "number", op: :<=, label: "Age <="],
               role: [
                 type: "select",
                 options: [{"Member", "member"}, {"Owner", "owner"}, {"Admin", "admin"}]
               ],
               active: [type: "select", options: [{"Yes", true}, {"No", false}]],
               confirmed_at: [type: "datetime-local"]
             ],
             form_module: LiveUI.Admin.User.Form,
             index_path: "/admin/users",
             live_module: SomeLiveModule,
             namespace: "admin",
             ownership: false,
             parent_relations: [
               department_id: [
                 name: :department,
                 owner_key: :department_id,
                 relationship: :parent,
                 search_field_for_title: :name,
                 schema_module: LiveUI.Admin.Department
               ],
               company_id: [
                 name: :company,
                 owner_key: :company_id,
                 relationship: :parent,
                 search_field_for_title: :name,
                 schema_module: LiveUI.Admin.Company
               ]
             ],
             resource: "user",
             resources: "users",
             schema_module: LiveUI.Admin.User,
             web_module: SomeLiveModule,
             uploads_opts: [],
             index_view: [
               formatters: [website: {&LiveUI.Formatters.link_/1, %{name: "Web"}}],
               actions: [
                 new: [
                   name: "New user",
                   allowed: true,
                   fields: [
                     :name,
                     :email,
                     :bio,
                     :age,
                     :website,
                     :company_id,
                     :department_id,
                     :role,
                     :active
                   ],
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
                   component: LiveUIWeb.Admin.UserLive.Deactivate,
                   allowed: true
                 ],
                 delete: [name: "Delete", allowed: true, function: &LiveUI.Queries.delete_ids/2]
               ],
               fields: [
                 :id,
                 :name,
                 :email,
                 :website,
                 :company_id,
                 :department_id,
                 :role,
                 :active,
                 :confirmed_at,
                 :inserted_at,
                 :updated_at
               ],
               preload: [:company, :department],
               function: &LiveUI.Queries.find_by_filter/3
             ],
             show_view: [
               formatters: [
                 email: &LiveUI.Formatters.copy/1,
                 bio: &LiveUI.Formatters.markdown/1,
                 website: &LiveUI.Formatters.link_/1
               ],
               actions: [
                 edit: [
                   name: "Edit",
                   allowed: true,
                   fields: [
                     :name,
                     :email,
                     :bio,
                     :age,
                     :website,
                     :company_id,
                     :department_id,
                     :role,
                     :active,
                     :confirmed_at
                   ],
                   optional_fields: [],
                   inputs: [],
                   function: &LiveUI.Queries.update/2,
                   changeset: &LiveUI.Changeset.update_changeset/3,
                   validate_changeset: &LiveUI.Changeset.update_changeset/3
                 ],
                 delete: [name: "Delete", allowed: true, function: &LiveUI.Queries.delete/2]
               ],
               fields: [
                 :id,
                 :name,
                 :email,
                 :bio,
                 :age,
                 :website,
                 :company_id,
                 :department_id,
                 :role,
                 :active,
                 :confirmed_at,
                 :inserted_at,
                 :updated_at
               ],
               preload: [:company, :department],
               function: &LiveUI.Queries.find_by_id/2
             ]
           } == config
  end

  test "config for custom actions" do
    config = LiveUI.Config.new(SomeLiveModule, LiveUI.Member.Contact)

    assert config[:index_view][:actions][:api_key] == [
             name: "Get api key",
             component: LiveUIWeb.Member.ContactLive.ApiKey,
             allowed: true
           ]

    assert config[:show_view][:actions][:send_email] == [
             name: "Send email",
             component: LiveUIWeb.Member.ContactLive.SendEmail,
             allowed: true
           ]
  end

  test "config for custom batch action" do
    config = LiveUI.Config.new(SomeLiveModule, LiveUI.Admin.User)

    assert config[:index_view][:batch_actions][:deactivate] == [
             name: "Deactivate",
             component: LiveUIWeb.Admin.UserLive.Deactivate,
             allowed: true
           ]
  end
end
