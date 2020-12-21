# The CLARK Application

[![Circle CI](https://circleci.com/gh/ClarkSource/application/tree/master.svg?style=svg&circle-token=d53f10f7b0c70f68f33d968edaff91fa16518404)](https://circleci.com/gh/ClarkSource/application/tree/master)

This is the main Rails & Ember app for [clark.de](clark.de).

You may see some references to Optisure. This is the pre-public-launch project
name, that may still be present in older areas of code / config.

This document is split into the following sections:

1. [**Background Info And Accounts**](#Background-Info-And-Accounts)
2. [**Quick Start Guide for installing the Application**](#Quick-Start-Guide-for-installing-the-Application)
 * Ruby
 * Database
 * Install Ember
 * Install Script
 * SMS Mock Service
 * Database User Changes
3. [**Full Install List**](#Full-Install-List)
 * Running local docker images for Insign and Hermes
4. [**Specifics for Austria**](#Specifics-for-Austria)
5. [**Extra Details Regarding Setup**](#Extra-Details-Regarding-Setup)
  * CMS DataGit
  * Git Commands
  * Environment variables
  * Seed users
  * Testing
  * Using Spring
  * logging
  * Static Page prototyping
  * Livereload
  * Ember Brand Config
  * Settings Management
6. [**Local Development Using Docker**](#Local-Development-Using-Docker)
  * This is work in progress but should soon help standardise development environments and make initial setup more consistent and faster

## Background Info And Accounts

### Accounts

- AWS:
  * [Setup AWS SSO](https://clarkteam.atlassian.net/wiki/spaces/CLOUD/pages/1666482574/Setup+AWS+SSO)
  * [AWS Login Link](https://keycloak.identity.flfinteche.de/auth/realms/FL%20Fintech%20E/protocol/saml/clients/amazon-aws)
- Slack:
  * [https://clarkworld.slack.com](https://clarkworld.slack.com)

### Deployments

#### Production and Staging Links

- production (`master`): [www.clark.de][production]
- staging 1 (`develop`): [staging.clark.de][staging]
- staging 2 http://staging-test-2.clark.de/
- ...
- staging 20 http://staging-test-20.clark.de/

Please go to the [#deployments channel in Slack to see current status of the environments](https://clarkworld.slack.com/archives/C08MSNB19)  
Please see [How to use Lex for staging deployments](https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/1635516431/How+to+use+Lex+for+staging+deployments)

## Quick Start Guide for Installing the Application

### Get up and running in development

Make sure these tools are installed:

- `xcode` (for macOS)
- `ruby@2.6.3`
- `postgres@9.5.x`
- [Ember](#install-node-&-ember)

#### XCode Installation (for macOS)

Install [homebrew](http://brew.sh).

Install development tools

```sh
xcode-select --install
```

### Ruby Installation

There are two options: `rbenv` (recommended) and `rvm`

#### `rbenv` (recommended)

Detailed instruction can be found on the [official website](https://github.com/rbenv/rbenv).

Short version of installation:

```sh
brew install rbenv
rbenv init

# list all available versions:
rbenv install -l
rbenv install 2.6.3
rbenv global 2.6.3
cd project_folder
```

When virtual environment was installed make sure bundler was also installed:

```
gem install bundler
bundle install
```

#### `rvm`

Detailed instruction can be found on the [official website](http://rvm.io/).

Short version of installation:

```sh
brew install gnupg
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E
curl -sSL https://get.rvm.io | bash -s stable
rvm install 2.6.3
```

In rare case the gpg --keyserver is failing, use this instead:

```sh
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
```

### Database Installation

Install progress

```sh
brew install postgresql@9.5
```

Your postgres server should ideally run as a service on your machine, in order
to have it running after system start:

```sh
cp /usr/local/Cellar/postgresql/9.5.<YOUR-VERSION>/homebrew.mxcl.postgresql<VERSION>.plist /Library/LaunchAgents/
```

For instance:

```sh
sudo cp /usr/local/Cellar/postgresql@9.5/9.5.22_1/homebrew.mxcl.postgresql@9.5.plist /Library/LaunchAgents/
```

Install a GUI for Postgres. For example [PostgresAPP](https://postgresapp.com/downloads.html) or [PgAdmin](https://www.pgadmin.org/)

```Clone the application git clone
cd <local source dev home>
git clone https://github.com/ClarkSource/application.git
```

### Install Node & Ember

First install [Volta](https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/1609367896/Volta+Node.js+Version+Management).

```sh
# On macOS with homebrew
brew install volta

# On any other UNIX system
curl https://get.volta.sh | bash
```

Then install the tool chain:

```sh
volta install node
volta install yarn
volta install ember-cli

yarn # make sure to run this in the repository root!

cd client
ember s
```

See [Setup of local Rails and Ember Development Environment](https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/53542965/Setup+of+local+Rails+and+Ember+Development+Environment) for further information

### Install Script

For your convenience there is install script available. You can use it to setup application with ease.

You can start by simply running:

```sh
./bin/install
```

but there are some additional variables worth using:

```sh
DOMAIN=0.0.0.0:3000    # configure CMS and bind it to this address
SKIP_DEPENDENCIES=true # you may want to skip installing gems, postgres, etc.
DROP_DB=true           # drop previously created DB before (a must unless a first installation)
APP_LOCALE=de-at       # configure app to run for a specific locale (e.g Austria)
```

Resulting command may look like:

```sh
APP_LOCALE=de-at DOMAIN=0.0.0.0:3000 ./bin/install
```

If you see error related to absence of database then edit install file in bin folder and temporarily comment out following line:

```
system "RAILS_ENV=test bundle exec rails db:drop
```

Bin install with retirement seeds

```sh
./bin/setup_testdata.sh
```

### SMS Mock Service

As part of the user sign up process on production a SMS verification code is sent out. When running locally the message is saved as a local file. You may get security warnings trying to view this in the browser. Please go directly to the directy and view: eg...

```application/tmp/letter_opener/1590677998_65462_b145e03/rich.html```

### Database User Changes

After cloning application repository and installing app you will have two additional databases: optisure_test and optisure_development

For these databases you will need to create new user so connection will be
possible:

```sh
psql
```

```sql
CREATE ROLE clark WITH SUPERUSER;
ALTER ROLE clark WITH LOGIN;
```

You can read much more details about users and roles in PostgreSQL in [manual](https://www.postgresql.org/docs/9.5/database-roles.html)  

## Starting Local Development Server

Start the Rails Server:

```sh
cd <local dev path>/application/bin/
rails s
```

Start the Frontend Ember App:

```sh
cd <local dev path>/application/
yarn
cd client
ember s
```

## Sample Seed data
There are 5 directories with seeds:
`db/seeds/development`
`db/seeds/de-de`
`db/seeds/de-at`
`db/seeds/shared`
`db/seeds/custom`

`db/seeds/development` is used for unit tests during `test_master_data`. If your unit test creates a lot of specific data then queries could be places here.
`db/seeds/de-de`, `db/seeds/de-at` and `db/seeds/shared` those are used for unit tests only. Do not add anything in those dirs as they will be removed once we get rid from those unit tests.

`db/seeds/custom` is designed to store manually added records for testing purposes e.g. the feature is under development but we want to create a DTE that has that feature flag
custom seeds should hold **only** upsert queries means record should be created or updated.

If you need to fulfill your local database with data execute the following commands from . 
`aws s3 cp s3://flfinteche-ci-production-eu-central-1-seeds/at/production ./db/seeds/de-at --recursive`
`aws s3 cp s3://flfinteche-ci-production-eu-central-1-seeds/de/production ./seeds/de-de --recursive`
`aws s3 cp s3://flfinteche-ci-production-eu-central-1-seeds/shared/production ./seeds/shared --recursive`
`bundle exec rails db:drop`
`bundle exec rails db:create db:structure:load`
`bundle exec rails db:migrate`
`bundle exec rails db:seed`

## Test Ops UI User Account to Login

Username: admin@example.com  
Password: Test1234

## Main Links

Rails: http://localhost:3000/  
(First load likely to take a few minutes)  

Ember: http://localhost:4200/  
(Direct access to the Ember)

Ops UI Admin: http://localhost:3000/de/admin

## Quick Start Tips

### Check frontend code for linting errors

```sh
FORCE_COLOR=1 yarn lerna run lint:js
```

See for [further linting Info](https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/1373077684/Linting)

### Rerun just selected Ember tests

```sh
ember test --server --filter="test name"
```

### Force Rails App to start with Clark2 Environment Variable set

```sh
CLARK2=true rails s -b 0.0.0.0
```

Use a private browser to avoid cookie issues then visit:
http://localhost:4200/de/app/contracts?cv=2
to force user to be in Clark 2

## Full Install List

The minimal setup is a rails and database server. The rails application has some extra dependencies.
- Insign is a service that is used when people digitally sign documents. A local test server can be used and is provided via a Docker image.,
- The Hermes Docker image is needed for the chat feature

### Install docker dependencies

You should have access to Clark's AWS instance to install the docker images (To request access check: https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/1631125854/How+to+request+access)

Install docker based on recommendations for you OS (e.g. homebrew for Mac or apt-get for Linux). Grab and run docker images based on [instruction](https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/60621998/Setup+Docker+Containers)

Before starting Rails application you should be sure that hermes and insign dockers are up and running. You can check it by
```
docker ps
```

Here is custom script that can be used to control that both hermes and insign are running:

```
clark_docker() {
 export WS_SHARED_SECRET=your_shared_secret
 eval $(aws ecr get-login --region eu-central-1 --no-include-email)
 docker kill hermes insign ||:
 docker rm hermes insign   ||:
 # Insign Server
 docker run -d -p 0.0.0.0:8080:8080 --name insign insign:latest
 # Hermes Server
 docker run -d -p 0.0.0.0:8801:8801 \
               -p 0.0.0.0:9901:9901 \
               -e WS_SHARED_SECRET=$WS_SHARED_SECRET \
               --name hermes \
               hermes:latest
}
```

## Specifics for Austria

## Running local app with Austria Locale

To run the app in your local environment with Austria locale for example, use APP_LOCALE=de-at.
The APP flag (APP=clark, APP=vkb etc.,) we had earlier that specifies the brand is no longer relevant
since WLs have a separate repository now.

Locale switching is managed by the locales addon under client-packages for frontend.
The locale for the base clark.de resides under client-packages/addons/locales/src/base/de/base/??.yml
And for Austria it resides under client-packages/addons/locales/src/base/de/at/??.yml

Do not add a locale mapping for additional locales if they have the same values as in base (i.e client-packages/addons/locales/src/base/de/base/??.yml)

## Extra Details Regarding Setup

### Git Utilities

| Command                                             | What is it for?                                                                                                                            |
|-----------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `rake app:branch:integration["new mandate funnel"]` | Will create or checkout the `integration-new-mandate-funnel` branch to work together on bigger features                                    |
| `rake app:branch:ticket["4711"]`                    | Will create or checkout the `JCLARK-4711` branch to work on that ticket. This command can only be run from master or an integration branch |
| `rake app:release`                                  | Will bump the version number, commit the change and tag the commit with the new version number and pushes everything up to GitHub          |

### Staging configurations

## Import / Export CMS Data

The CMS is split into two:
* Comfy CMS: The "old" CMS, part of the Rails application
* Contentful CMS: This "new" CMS. This has it's own repository https://github.com/ClarkSource/cms-frontend It is not needed in order to get the basic rails app up and running locally.

The data folder can by found in `db/cms_fixtures/[locale]/`

### Development

TODO: @Yousry, please add background info and update

If you like you can set `cms_fixtures` to `true` in your local settings file in `config/settings.local.yml`.
Then the CMS data is automatically populated from the cms_fixtures on the filesystem.
Just make sure you have created a corresponding site via the admin interface.

So when you want to use the data in the folder `db/cms_fixtures/de/` then you need to have a site with the identifier `de`.

Export to data folder

```bash
rake cms:export FROM=[locale] TO=[locale]
```

```bash
sudo chmod 777 -R [path_to_the_rails_app]/public/system
```

Import from existing data folder

```bash
rake cms:import FROM=[locale] TO=[locale]
```

### Configure environment variables

Run following commands or add it (to persist) to `~/.bash_profile` or
`~/.zshrc`:

```sh
export WS_SHARED_SECRET=some_secret_for_the_websockets
export WS_MESSAGES_API_END_POINT=0.0.0.0:3000
```

### Running the app with installed CMS

Standard Rails startup...

```
bundle exec rails server -b 0.0.0.0
```

### If you use something like [pow](http://pow.cx)

When you plan to use POW make sure to specify a DOMAIN variable in install script:

```sh
DOMAIN=clark.test bin/install
```

Afterwards just run the server using:

```bash
bundle exec rails server -b 0.0.0.0
```

### Run the background jobs

```bash
RAILS_ENV=<ENVIRONMENT> bin/delayed_job start
```

### Seed users - login information

Full list of users can be found in Users table. You can use [PgAdmin](https://www.pgadmin.org/) or other tool to inspect the database.

Example user's email that can be used for login: `mark.megaportfolio@seedsexample.com`

All seeded users have following password: `Test1234`

### Testing

`bin/install` will also set your test environment.
You can then get the command ci uses to run the tests by doing:

```bash
#or just display the command with
> bin/ci-specs
```

Bear in mind that this is the command run for **master** builds.

### Using SPRING

Spring is a Rails application preloader. It speeds up development by keeping your application running in the background
so you don't need to boot it every time you run a test, rake task or migration.

It makes running test or rails console much faster once you already have something else running. You can prepend spring
for the majority of commands (specially rspec and rails).

```bash
> bundle exec spring rails s
> bundle exec spring rails c
> bundle exec spring spec
```

You can also do some more nice things, for instance using the `onchange` binary from npm:

```bash
>  onchange "app/services/robo_advisor.rb" -- bundle exec spring rspec spec/services/robo_advisor/private_liability_insurance_spec.rb
```

OBS: We do not have spring binstubs

### Logging

Logging of [MiniMagick](https://github.com/minimagick/minimagick)
commands is disabled in the initializer
`config/initializers/mini_magick.rb`. If you need to see what is going
on, just comment out the line.

## Static Page Prototyping

To quickly develop designs you can put pages into `views/prototype` and
access them using `http://localhost:3000/prototype/<PAGENAME>`.
Views can be written in any language supported by the installed Gems
(default: `filename.html.haml` for HAML and `filename.html.erb` for ERB or just `filename.html` for plain HTML).

### Partials

To include partials in your pages, put them into the `app/views/prototype`
directory, then reference them from another file.
Partials must start with an underscore and may not contain dashes, like
`_some_partial.html.haml`.
To include them, write `<%= render 'prototype/some_partial' %>`. Note
that the **leading underscore and the file extension are omitted**.

### Layout

The common layout for all pages in the prototye is located in
`app/views/layouts/prototype.html.erb`. It includes the Stylesheets from
`app/assets/stylesheets/prototype/base.scss`. When you develop new
styles, and want to integrate them, `@import` them into `base.scss`.

### Assets

All Javascript is loaded from `app/assets/javascripts/prototype/index.js`.
Additional Javascript that is only needed for prototyping should go into
that directory. All Javascript that should be loaded in the prototype
layout should be added to `index.js` using `require` comments.

To reference images from HTML, use the [`image_tag` helper][imagetag].
An image in `app/assets/images/xxx.jpg` would be referenced by
`<%= image_tag 'xxx' %>`.
Note: you can omit the file extension to make Rails chose the right one
automatically. To add classes to an image, use
`<%= image_tag 'xxx', class: 'whatever-classfoo' %>`.

To reference images from SCSS/SASS, use the built in helpers:

- `image-url("rails.png")` becomes `url(/assets/rails.png)`
- `image-path("rails.png")` becomes `"/assets/rails.png"`.

The more generic form can also be used:

- `asset-url("rails.png")` becomes `url(/assets/rails.png)`
- `asset-path("rails.png")` becomes `"/assets/rails.png"`

For more information [refer to the guide][guide].

### Livereload

To get livereload functionality for developing CSS, run:

`bundle exec guard -d -P livereload`

in a Terminal inside the root directory of the repo. Livereload can currently be enabled through respective
browser[extensions](http://livereload.com/extensions/).

### Test persistence stats

To show statistic of records persisted in db during test execution, run rspec with:

`PERSISTENCE_STATS=true bundle exec rspec spec/`

### SQL Query source line logging

To show exact line of code that triggers database call in logs, make sure `SHOW_DB_QUERY_SOURCE=true` is exported.

### Ember Brand Config for frontend

We have brand config to support different brands/locales. Now each APP_LOCALE will have it's own configuration object at runtime.
To access the config object at runtime, use the 'config' service and do this.config.getConfig('config-object-name').
The config file for Austria for example resides under client/brand/clark/js/de-at/index.js and for Germany client/brand/clark/js/de-de/index.js.
If you're adding or updating the config object, make sure to update the brandconfig interface under client/app/interfaces/brand-config.ts.

### Settings management

Since Clark Application becomes bigger and bigger and supports multiple labels (with a plan to grow) we need to
maintain settings and validate them.

Current settings are listed here:
https://clarkteam.atlassian.net/wiki/spaces/JCLARK/pages/1650688468/Whitelabel+Settings

Every developer working on settings, after adding, changing, removing them, please use the following tasks and
transfer the changes to the page above.

Tasks:
`rake documentation:settings_description`
Search for new settings for all labels and add them to existing ones in the settings_descriptions.yml file.
Old descriptions will be preserved. New ones will be added with "?" as a description.
Developers should be responsible for filling those up.

`rake documentation:settings`
Use existing settings_descriptions.yml file, fetch and parse settings.yml for all brands and prepare a temp markup file.
This file's content should be copied and put into Confluence page.

`rake documentation:settings_validation`
Assuming your changes in settings are correct - generate yml file with type validations according to current state.

## Local Development Using Docker

This is Draft/Work In Progress!

### Using docker-compose to run the application

To run the application as docker images, we have the following docker files
- Docker-frontend
- Docker-backend

We wish to run all the containers with docker-compose. To achieve that we have the compose.yml file.
It consists of hermes, insign, database, frontend and application. The application depends on all the before
 mentioned images and containers

To be able to run docker-compose you must complete the following steps:
1) Have docker and docker-compose installed on the machine
2) Sign in to amazon ecr: `aws ecr get-login --region eu-central-1 --no-include-email | bash`
3) Once signed in, run the following command: `docker-compose -f compose.yml up`

NOTE: Once you run the file it will do all the setup for you, it installs everything necessary in the container.
 It also setups up the database. Once the database has been setup and you re-run the command, it will not do everything
 all over again and directly start the servers

If you wish to configure for example the environment variables, they can be done from the compose.yml file.
 i.e APP and RAILS_ENV can be set to your desired value (devk, production etc) through the compose.yml environment vars

NOTE: To avoid any hiccups, please remove the existing config/database.yml file if you have one already.
 It will bbe copied over from database.yml.docker automatically.

### Bootstraping database

To bootstrap the database, we have script:
- scripts/dev_ci_db_bootstrap.sh
and
- ./scripts/bootstrap_db.sh

Both of them take two arguments a BRAND and RAILS_ENV
 - BRAND => i.e clark, devk, groot, weasley, vkb etc
 - RAILS_ENV => i.e development, production, test etc
:NOTE - if you wanna run locally please make sure that you have the config/database.yml file.. if not please create one
and copy the contents from config/database.yml.example or better config/database.yml.docker

- USAGE for development (this script creates database and test database)
 `BRAND=clark RAILS_ENV=development scripts/dev_ci_db_bootstrap.sh`
OR
- (this script assumes the database is already created) `BRAND=clark RAILS_ENV=development scripts/bootstrap_db.sh`

### Local Development in Docker (Whitelabel)

If you with to use Docker for your local development setup - there are some commands that you may need to get familiar with.

First of all you will need to install docker-sync

```sh
gem install docker-sync
```

After that you need to hit

```sh
docker-sync start
```

And wait few minutes until external volume container is built. Then you may proceed with the rest.

Other useful commands:

```sh
docker-sync stop // if you just want to stop the daemon
docker-sync clean // if you want to cleanup the docker-sync container and mount
docker-sync sync // if for some reason you fell out of sync
```

It is highly recommended to read through the Makefile itself. All commands can be prefixed with `APP=brand_name` which will
instruct docker to create app-specific image and container. Containers does not contain application code - everything is
attached via volumes. `APP` variable will be exposed and already set once in container.

In order to make it work you need

For most cases you will most likely use:

```sh
make backend_build # build backend base and label
make backend_setup # setup backend from scratch (including db setup) - good for initializing new labels locally
make backend_refresh # refresh containers, gems and migrate database
make backend_reset # refresh containers, gems and drop and prepare database
make backend_server # if you need only the backend server
make backend_dev # ssh to the container and work as you want, run rake tests, start server, run specs, etc

make frontend_build # build frontend base (only base is needed, since the build does not depend on label)
make frontend_server # if you need only the frontend server
make frontend_dev # ssh to the container and work as you want, run tests, etc

make watch_emails # start guard to watch tmp directory for emails and open then in the browser
```

## Gems

`contract_price_calculator` functionality implemented as a separate engine in the folder
`gems/contract_price_calculator`
Supposed to move this gem into the separate repository and develop/support it there.

## API Documentation

We use [rswag](https://github.com/rswag/rswag) to create and show api documentation from integration specs.
These specs can be accessed from `clark-....de/api/docs` in all instances.
To regenrate documentation when we add or update rspec integration, run `bundle exec rake swagger:generate`.
