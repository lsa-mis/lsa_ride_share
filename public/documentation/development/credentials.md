# Credentials
[Home](./README.md) / [Development](development/README.md)

We use the standard Rails credentials system to manage sensitive information such as authorization credentials, api keys etc. This is a two part system that uses a master key to decrypt the credentials file. The master key is NEVER stored in the repository, but the credentials file is. (*By default, Ruby on Rails will add the appropriate .key file to the .gitignore file.*)

In Ruby on Rails, credentials can be separated by environment. This is useful for things like API keys that are different in development and production.

## Setup

### Add development credentials

```bash
rails credentials:edit --environment development
```

This will open the credentials file for the development environment. (* /config/credentials/development.key will be added to the .gitignore file.*)

### Editing Credentials (in VS Code)

Open the development credentials file in VS Code.
```bash
EDITOR="code --wait" rails credentials:edit --environment development
```

Save your changes and close the file. The credentials file will be encrypted and saved.

### Formatting credentials

The credentials file is a YAML file. It is recommended to use the following format for credentials.

```yaml
service_name:
  app_id: 123
  app_secret: 345
```

## Using Credentials

Credentials can be accessed within the application, usually in config files using the credentials method.

```ruby
Rails.application.credentials.dig(:service_name, :app_id)
```

For example, in the Devise initializer, we can use credentials to set oauth providers, referencing them through the credentials method. In the following example, we set up Google OAuth2 as an OmniAuth provider, define the authorized domains (```lsa.umich.edu, umich.edu```). This will allow users to log in with their U-M Google accounts, but not with other Google accounts.

```ruby
  # OmniAuth Providers

  config.omniauth :google_oauth2, Rails.application.credentials.google_oauth2[:APP_ID], Rails.application.credentials.google_oauth2[:APP_SECRET], scope: "userinfo.email, userinfo.profile", prompt: "select_account", image_aspect_ratio: "square", image_size: 50, hd: %w[umich.edu lsa.umich.edu]
```

## References

- [Rails Guides: Credentials](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Rails Guides: Configuring Rails Applications](https://guides.rubyonrails.org/configuring.html#creating-and-customizing-rails-generators)