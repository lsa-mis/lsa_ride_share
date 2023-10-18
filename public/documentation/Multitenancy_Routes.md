### [Home](./README.md)

## Routing scheme:

| **Function**        | **Pattern**                                | **Example**                                      |
|---------------------|--------------------------------------------|--------------------------------------------------|
| **Working**         | appname-staging.umich.edu/                 | avm-staging.umich.edu/                           |
|                     | appname-production.umich.edu/              | avm-production.umich.edu/                        |
|                                                                                                                     |
| **Primary**         | appname.umich.edu/                         | avm.umich.edu/                                   |
|                     | appname.umich.edu/account                  | avm.umich.edu/account                            |
|                                                                                                                     |
| **Multi-tennancy**  | appname.department.umich.edu/              | avm.lsa.umich.edu/                               |
|                     | appname.department.umich.edu/account       | avm.lsa.umich.edu/account                        |
|                     | appname.department.umich.edu/team          | avm.lsa.umich.edu/lsats_classroom_support        |
|                     | appname.department.umich.edu/team/account  | avm.lsa.umich.edu/lsats_classroom_support/account|
| ***Alternative***                                                                                                   |
| **Multi-tennancy**  | department.umich.edu/appname/              | lsa.umich.edu/avm/                               |
|                     | department.umich.edu/appname/account       | lsa.umich.edu/avm/account                        |
|                     | department.umich.edu/appname/team          | lsa.umich.edu/avm/lsats_classroom_support        |
|                     | department.umich.edu/appname/team/account  | lsa.umich.edu/avm/department/team/account        |
