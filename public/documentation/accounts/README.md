# Accounts
[Home](../README.md)

There are three primary types of accounts. 

| **AccountType**         | **Pattern**                                                                      |
|-------------------------|----------------------------------------------------------------------------------|
| **[Personal Account](../accounts/personal_accounts.md):**   | ***required*** for each user. Set by default when the user initially signs up.   |
| **[Team Account](../accounts/team_accounts.md):**       | A collection of personal accounts (team has_many accounts as members) and/or domain accounts). A **Team Account** has one or more **AccountOwners**. A team account can have other teams as members.|
| **[MCommunity Account](../accounts/mcommunity_accounts.md)** | A Team account that has it's membership defined in an[ MCommunity group](https://mcommunity.umich.edu).  ***Cannot be tied to an idividual account. Must be a [ MCommunity group](https://mcommunity.umich.edu) Group created for the application.*** |

Using these tools, we can enable rich, ad-hoc collaborataion and sharing around resources. 

Each application has has an associated team of maintainers. 

```mermaid

graph TD
 

    APP[Application] --> TEAMS(fa:fa-users Teams)
  
    APP[Application] --> |MCommunity|SCH(fa:fa-graduation-cap Schools)
    APP[Application] --> |MCommunity|C(fa:fa-graduation-cap Colleges)
    APP[Application] --> COL(fa:fa-graduation-cap Colleges)   
    APP[Application] --> |MCommunity| MAINT(fa:fa-cloud Maintainers)
    
    SCH --> SCHTEAMS(fa:fa-users Teams)
    SCH --> C(fa:fa-sitemap Departments)
  
    C --> D(fa:fa-users Teams)
    C --> E(fa:fa-user Accounts)
    C --> |MCommunity|F(fa:fa-cloud Maintainers)

    COL --> COLD(fa:fa-users Teams)
    COL --> COLE(fa:fa-user Accounts)
    COL --> |MCommunity|COLEF(fa:fa-cloud Maintainers)

    style MAINT stroke:green,stroke-width:2px,color:green,fill:white;

```

