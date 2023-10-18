# Multi-tenancy
[Home](./README.md) / [Accounts](accounts/README.md) / [Requesting Access](accounts/requesting_access.md)


ModelRails is set up to support multi-tenancy. This means that you can have multiple accounts, each with their own data. This is useful for a number of reasons: you can have a separate account for each department, or you can have a separate account for each of your users. From this starting point, users can have greater flexibility in how they share data with each other.

## Development Setup

To work with multitenancy and allow users to create new tenants without re-booting the application,  we need to configure Rails to allow multiple domains. We can do this by adding the following to our `config/application.rb` file:

    config.hosts = nil

This us to use a service like lvh.me to create a local domain for each tenant. We can then use this domain to access the application. For example, if we create a tenant with the name `foo`, we can access the application at `http://foo.lvh.me:3000/`.

http://lvh.me:3000/


User 

``` mermaid

classDiagram
  class User {
    id: integer
    name: string
    created_at: datetime
    updated_at: datetime
  }

  class Account {
    id: integer
    user_id: integer
    created_at: datetime
    updated_at: datetime
  }

  class Team {
    id: integer
    owner_id: integer
    created_at: datetime
    updated_at: datetime
  }

  class Department {
    id: integer
    account_id: integer
    created_at: datetime
    updated_at: datetime
  }

  class Profile {
    id: integer
    account_id: integer
    created_at: datetime
    updated_at: datetime
  }

  class OmniAuthService {
    id: integer
    account_id: integer
    created_at: datetime
    updated_at: datetime
  }

  User --> Account
  User --> OmniAuthService
  Account --> Team
  Account --> Department
  Account --> Profile
  Team <-- Department


```
