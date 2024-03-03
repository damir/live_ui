import_if_available(Ecto.Query)
import_if_available(Ecto.Changeset)

Application.put_env(:elixir, :ansi_enabled, true)

timestamp = fn ->
  {_date, {hour, minute, _second}} = :calendar.local_time()

  [hour, minute]
  |> Enum.map(&String.pad_leading(Integer.to_string(&1), 2, "0"))
  |> Enum.join(":")
end

IEx.configure(
  colors: [
    syntax_colors: [
      number: :light_yellow,
      atom: :light_cyan,
      string: :light_black,
      boolean: :red,
      nil: [:magenta, :bright]
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline]
  ],
  default_prompt:
    "#{IO.ANSI.green()}%prefix#{IO.ANSI.reset()}" <>
      "[#{IO.ANSI.magenta()}#{timestamp.()}#{IO.ANSI.reset()}" <>
      "::#{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()}]>",
  alive_prompt:
    "#{IO.ANSI.green()}%prefix#{IO.ANSI.reset()}" <>
      "(#{IO.ANSI.yellow()}%node#{IO.ANSI.reset()})" <>
      "[#{IO.ANSI.magenta()}#{timestamp.()}#{IO.ANSI.reset()}" <>
      "::#{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()}]>",
  history_size: 50,
  inspect: [
    pretty: true,
    limit: :infinity,
    width: 80,
    custom_options: [sort_maps: true]
  ],
  width: 80
)

alias LiveUI.Admin.{Company, Contact, Department, Product, Session, User}
alias LiveUI.Member.Contact
alias LiveUI.Accounts.UserToken
alias LiveUI.Repo

# records
company = Repo.get(Company, 1)
department = Repo.get(Department, 1)
user = Repo.get(User, 1)
product = Repo.get(Product, 1)

# protocol
index_view = LiveUI.index_view(user)
show_view = LiveUI.show_view(user)

# config
config = LiveUI.Config.new(LiveUI.Admin.User, User)
