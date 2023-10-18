# Invitations:
[Home](./README.md) / [Accounts](accounts/README.md) / [Requesting Access](accounts/requesting_access.md)

An invitation allows a new user to create an account (sign-in via oauth) to an application. Invitations can be sent by admins, super-users and department-admins. 
  ```
  ## invitation (basic)
  email: string
  resource_id: integer  
  account_role: integer
  invited_by: :user_id 
  ```
