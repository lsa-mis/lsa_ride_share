# AccountRole:
[Home](./README.md) / [Accounts](accounts/README.md)

Each account has a role. Roles are used to delineate what actions are allowed on resources. Here are the default roles that are available within our systems by default (or configuration?). They are broken down by the scope that they are associated with. 


Basic Roles
>  - Read: Can read and clone this resource.
>  - Write: Can read, clone, and push to this resource.
>  Can also manage issues and pull requests.
>  - Maintain: Can read, clone, and update this resource. [* If the resource is a single entity, versus if it is a collection?] They can also and some resource settings.
>  - Owner: Can read, clone, and update this resource. Owners also manage resource settings, including adding collaborators.

  ### Application
  
  Application owners have complete administrative access to your application. This role should be limited, but to no less than two people, in your organization.
  
    - adding account owners, departments and roles. 
    - editing content on application itself (landing page, about us, etc...) (if enabled).

  
  By default, the admins will be W&ADS Rails team. The tasks will generally be done using the console? (**Initially?)
  
  > [MCommunity Method](MCommunity.md)
    When creating a new application, create a MCommunity group following the pattern ```appname-admins``` and add the ```lsa-was-rails-admins``` group to it. 


  |   Role                    |  Permissions                       | scope                                              |Description |
  |---------------------------|------------------------------------|---------------------------------------------------|----------|
  |   **owner:****              |   [create, read, update, destroy]  | Application wide                                  | Can update editable application configs, manage collaborators |
  |   **maintainer:**   |   [create, read, update, destroy**]| departments and accounts                | Can add and remove departments, teams and accounts. |

  
  ### Department
  |   Role                    |  Permissions                       | scope                                              |Description |
  |---------------------------|------------------------------------|---------------------------------------------------|----------|
  |   **owner:****              |   [create, read, update, destroy]  | Department wide                                  | Department resrouces including managing maintainers |
  |   **maintainer:**         |   [create, read, update, destroy**]| Department wide                                  | Department resrouces including members |
  |   **department-admin:**   |   [create, read, update, destroy**]| department resources and accounts                 | All resources within department |

  > Department owners are maintained in an MCommunity group named ***appname_department_owners***


  ### Team
  |   Role                    |  Permissions                       | scope                                              |Description |
  |---------------------------|------------------------------------|---------------------------------------------------|----------|
  |   **owner:****              |   [create, read, update, destroy]  | Team wide                                  | Team resrouces including managing maintainers |
  |   **maintainer:**         |   [create, read, update, destroy**]| Team wide                                  | Team resrouces including members |
  |   **team-admin:**   |   [create, read, update, destroy**]| Team resources and accounts                 | All resources within department |

  > Teams are maintained in within the application and do not utilize MCommunity.

 
 #### Invitations
  |   Role                    |  Permissions                       | scope                                             | Description |
  |---------------------------|------------------------------------|---------------------------------------------------|--|
  |   **owner:**              |   [create, read, update, destroy]  | application wide                                  | All users  |
  |   **maintainer:**         |   [create, read, update, destroy***]| application wide                                  | All users? (should this role be scoped narrower?) |
  |   **department-admin:**   |   [create, read, update, destroy***]| department resources and accounts                 | All user within department |
  |   **owner:**              |   [create, read, update, destroy***]| resources created by owner ****     |  All users within organization ? do we allow sharing outside? How?

  #### Resources
  |   Role                    |  Permissions                       | scope                                             |
  |---------------------------|------------------------------------|---------------------------------------------------|
  |   **owner:**              |   [create, read, update, destroy***]| resources created by or shared with by creator    |
  |   **editor:**             |   [read, update]                   | resources shared  by an owner                     |
  |   **recorder:**           |   [create, read, update]           | resources created by recorder or assigned by owner|
  |   **viewer:**             |   [read]                           | resources shared by owner                         |

  ** ***The role of 'admin' is assigned to a MCommunity group to encourage transparency and redundancy.***
  *** ***Destroy may be implemented as 'archive' for certain roles and resources.***
  **** ***If application allows users to invite external users?.***