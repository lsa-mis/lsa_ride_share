# Art Survey
![](https://img.shields.io/badge/Ruby%20Version-3.1.2-red) ![](https://img.shields.io/badge/Rails%20Version-7.0.4-red) ![](https://img.shields.io/badge/Postgresql%20Version-14.4-red)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

The scope of this application is to support and simplify LSA departments business process in reserving cars.

## Getting Started (Mac)

### Prerequisites
- postgresql (correct version and running)
- This application uses University of Michigan Shibboleth + DUO authentication

To get a local copy up and running clone the repo, navigate to the local instance and start the application
```
git clone git@github.com:lsa-mis/lsa_ride_share.git
cd art_survey
bundle
bin/rails db:create
bin/rails db:migrate
bin/dev
```

  ## Authentication
  - Omniauth-SAML
    - Shibboleth + DUO
    - Devise

## Support / Questions
  Please email the [LSA W&ADS Rails Team](mailto:lsa-was-rails-devs@umich.edu)
