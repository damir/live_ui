alias LiveUI.Admin.{Company, Department, User, Product}
alias LiveUI.Repo

# admin
admin =
  PaperTrail.insert!(%LiveUI.Accounts.User{
    name: "Admin",
    email: "admin@example.com",
    role: :admin,
    hashed_password: Bcrypt.hash_pwd_salt("password")
  })

n = 100

for _n <- 1..n do
  Repo.insert!(%LiveUI.Member.Contact{
    name: Faker.Person.name(),
    email: Faker.Internet.email(),
    phone: Faker.Phone.EnUs.phone(),
    user_id: admin.id
  })
end

companies =
  for _n <- 1..n, into: [] do
    company =
      Repo.insert!(%Company{
        name: Faker.Company.name(),
        description: Faker.Company.bs() |> String.capitalize()
      })

    for _n <- 1..Enum.random(1..5) do
      Repo.insert!(%Department{
        name: Faker.Industry.industry(),
        location: Faker.Address.city(),
        company: company
      })
    end

    company
  end

for _n <- 1..n do
  age = Enum.random(18..100)
  company = Enum.random(companies) |> Repo.preload(:departments)
  department = Enum.random(company.departments)

  PaperTrail.insert!(%User{
    name: Faker.Person.name(),
    email: Faker.Internet.email(),
    bio: Faker.Person.title(),
    age: age,
    website: Faker.Internet.url(),
    active: Enum.random([true, false]),
    confirmed_at:
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)
      |> NaiveDateTime.add(-age, :day)
      |> NaiveDateTime.add(-age, :hour)
      |> NaiveDateTime.add(-age, :second),
    role: Enum.random([:member, :owner, :admin]),
    company: company,
    department: department
  })
end

for _n <- 1..n do
  Repo.insert!(%Product{
    name: Enum.random([Faker.Commerce.product_name(), Faker.Commerce.product_name_product()]),
    description: Faker.Commerce.department(),
    price: Enum.random(1000..1_000_000),
    currency: Enum.random([:USD, :EUR]),
    stock: Enum.random(0..1_000_000),
    unit: Enum.random(~w(ounce pound gallon pint foot inch)),
    variants: Enum.map(1..Enum.random(1..5), &(&1 && Faker.Commerce.product_name_adjective())),
    company: Enum.random(companies)
  })
end
