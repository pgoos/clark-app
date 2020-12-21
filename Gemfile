# frozen_string_literal: true

source "https://rubygems.org"

## RAILS, EXTENSIONS ------------------------------------------------------------------------------
gem "rails", "5.2.4.3"
gem "combine_pdf", "1.0.21"
gem "puma", "5.1.1"
gem "puma-metrics", "1.2.0"
gem "sanitize"
gem "renum", "1.4.0"
gem "inherited_resources", "1.12.0"
gem "has_scope", "0.7.2"
gem "hashie", "4.1.0"
gem "hashie-forbidden_attributes", "0.1.1"
gem "email_validator", "2.2.2"
gem "validates_zipcode", "0.3.3"
gem "phony_rails", "0.14.13"
gem "money-rails", "1.13.3"
gem "chronic", "0.10.2"
gem "ibandit", "~> 1.2.3"
gem "text-hyphen", "1.4.1"
gem "facets", "3.1.0", require: false
gem "rack-cors", "1.1.1", require: "rack/cors"
gem "prometheus_exporter", "0.6.0"
gem "luhn", "1.0.2"
gem "telephone_number", "1.4.9"
gem "sprockets", "3.7.2"

## STATE MACHINE ----------------------------------------------------------------------------------
gem "state_machines", "0.5.0"
gem "state_machines-activerecord", "0.6.0"

## DB, STORAGE ------------------------------------------------------------------------------------
gem "migration_data", "0.6.0"
gem "groupdate", "5.2.1"
gem "pg", "1.2.3"
gem "activerecord-import", "1.0.7"
gem "active_record_union", "1.3"
gem "yaml_db"

## BACKGROUND JOBS, QUEUE -------------------------------------------------------------------------
gem "daemons", "1.3.1"
gem "delayed_job", "4.1.9"
gem "delayed_job_active_record", "4.1.4"
gem "delayed_job_web", "1.4.3"
gem "activejob_dj_overrides", "0.2.0"
gem "wisper", "2.0.1"
gem "wisper-activerecord", "1.0.0"
gem "concurrent-ruby", "~> 1.1"

## LOGS, METRICS ----------------------------------------------------------------------------------
gem "grape_logging", "1.8.4"
gem "lograge", "0.11.2"
gem "logstash-event", "1.2.02"

## GRAPE API --------------------------------------------------------------------------------------
gem "grape", "1.5.1"
gem "grape-entity", "0.8.2"
gem "grape-swagger", "1.3.1"
gem "grape-swagger-rails", "0.3.1"
gem "grape-swagger-entity", "0.5.1"
gem "grape-swagger-representable", "0.2.2"

## JSON API --------------------------------------------------------------------------------------
gem "jsonapi-serializers"

## MANAGEMENT API ---------------------------------------------------------------------------------
gem "swagger-blocks"

## TRANSLATION, LOCALIZATION ----------------------------------------------------------------------
gem "mobility", "0.5.0"
gem "countries", "2.1.4", require: "countries/global"
gem "country_select", "3.1.1"

## HTTP/RPC/SOAP CLIENTS --------------------------------------------------------------------------
gem "httpclient", "2.8.3"
gem "ripcord", git: "https://github.com/ClarkSource/ripcord",
               ref: "29c48a3a17cb85e750f321c9e06bc08ea937a0ba"
gem "savon", "2.12.1"
gem "faraday", "~> 0.17.3"
gem "http", "~> 4.4.1"

## SFTP
gem "bcrypt_pbkdf", "~> 1.0"
gem "ed25519", "~> 1.2"
gem "net-sftp", "~> 3.0"

## AUTH, SECURITY, SOCIAL NETWORKS ----------------------------------------------------------------
gem "devise", "4.7.3"
gem "devise-security", "0.14.3"
gem "omniauth", "1.9.1"
gem "omniauth-facebook", "8.0.0"
gem "omniauth-apple", github: "nhosoya/omniauth-apple"
gem "omniauth-rails_csrf_protection", "0.1.2"
gem "jwt", "2.2.2"
gem "attr_encrypted", "3.1.0"
gem "koala", "3.0.0"
gem "rack-attack", "6.3.1"
gem "rails_same_site_cookie"

## FRONTEND, VIEW HELPERS  ------------------------------------------------------------------------
gem "trix"
gem "uglifier", "4.2.0"
gem "coffee-rails", "5.0.0"
gem "jquery-rails", "4.4.0"
gem "jquery-ui-rails", "6.0.1"
gem "best_in_place", "3.1.1"
gem "chosen-rails", "1.9.0"
gem "dropzonejs-rails", "0.8.5"
gem "modernizr-rails", "2.7.1"
gem "browser", "2.7.1"
gem "autoprefixer-rails", "9.8.6.3"
gem "bootstrap_form", ">= 4.2.0"
gem "sass-rails", "6.0.0"
gem "font-awesome-sass", "~> 5.15.1"
gem "inline_svg", "1.7.2"
gem "haml-rails", "2.0.1"
gem "haml", "5.2.0"
gem "kaminari", "1.2.1"
gem "bootstrap4-kaminari-views", "1.0.1"
gem "active_link_to",           "1.0.5"
gem "simple_form", "5.0.3"
gem "enum_help", "0.0.17"
gem "draper", "4.0.1"
gem "lodash-rails", "4.17.15"

## PARSERS, SERIALIZERS, FILE UPLOAD/PROCESSING ---------------------------------------------------
gem "nokogiri", "1.10.10"
gem "jbuilder", "2.10.1"
gem "nori", "2.6.0"
gem "simple_xlsx_reader", "1.0.4"
gem "simple-spreadsheet", "0.5.0"
gem "smarter_csv", "1.2.6"
gem "pdfkit", "0.8.4.3.2"
gem "rubyzip", "1.3.0"
gem "icalendar", "2.7.0"
gem "active_model_serializers", "0.10.12"

# FILE UPLOAD
gem "mini_magick", "4.11.0"
gem "carrierwave", "1.2.1"
gem "carrierwave-base64", "2.8.0"
gem "fog-aws", "3.7.0"

## MAILERS, NOTIFICATIONS, TRACKING ---------------------------------------------------------------
gem "ahoy_matey", "2.1.0"
gem "uuidtools", "2.2.0"
gem "ahoy_email", "0.5.2"
gem "mandrill_dm", "1.3.6"
gem "gibbon", "3.3.4"
gem "premailer-rails", "1.11.0"
gem "sentry-raven"
gem "rails_email_preview", git: "https://github.com/ClarkSource/rails_email_preview", branch: "rails5"
# NOTE: Gem `config` must be loaded before `aws-sdk`
# NOTE: > 1.4.0 breaks some tests
gem "config", "2.2.3"
gem "aws-sdk-s3", "~> 1.67"
gem "aws-sdk-sns", "~> 1.24"
gem "aws-sdk-sqs", "~> 1.35"

## MIDDLEWARES, ENV -------------------------------------------------------------------------------
gem "shortener"

## TERMINAL ---------------------------------------------------------------------------------------
gem "progress_bar", "1.3.3"
gem "table_print", "1.5.7"

## PERFORMANCE ------------------------------------------------------------------------------------
gem "bootsnap", "1.5.1", require: false
gem "connection_pool", "2.2.3"
gem "memoist", "0.16.2"
gem "gc_stats", "~> 1.0"

## DRY --------------------------------------------------------------------------------------------
gem "dry-struct"
gem "dry-validation"
gem "dry-auto_inject", "0.7.0"

## TESTING ----------------------------------------------------------------------------------------
gem "capybara", "~> 3.34.0"
gem "activerecord-nulldb-adapter", "0.5.1"

## DOCUMENTATION ----------------------------------------------------------------------------------
gem "rswag-api"
gem "rswag-ui"

## ENVIRONMENT SPECIFIC GEMS ----------------------------------------------------------------------
group :development do
  ## Code Organization
  gem "annotate", require: false

  # REPL and exceptions
  gem "web-console", "3.7.0"
  gem "better_errors"
  gem "rcodetools"
  gem "fastri"
  gem "strong_migrations", require: false

  # Linters
  gem "rubocop", "1.6.1", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-git", require: false
  gem "rubocop-rails", require: false
  gem "bullet"

  # Analyze code for potentially uncalled / dead methods
  gem "bundler-audit"
  gem "brakeman", require: false

  # Debugging
  gem "ruby-debug-ide"
  gem "debase"

  # IMPORTANT: mini profiler monkey patches, so it better be required last
  #  If you want to amend mini profiler to do the monkey patches in the railties
  #  we are open to it.
  gem "stackprof"
  gem "flamegraph"
  gem "rack-mini-profiler", "2.2.0", require: false
  gem "ruby_gntp"

  gem "binding_of_caller"
end

group :test do
  gem "shoulda-matchers", "3.1.3"
  gem "shoulda-callback-matchers"
  gem "simplecov", require: false
  gem "simplecov-json", require: false
  gem "selenium-webdriver", "3.142.3"
  gem "state_machines-rspec", "0.6.0"
  gem "capybara-screenshot"
  gem "database_cleaner-active_record"
  gem "timecop"
  gem "rspec_junit_formatter", "0.4.1"
  gem "rspec-retry", "0.6.2"
  gem "vcr", "~> 6.0.0"
  gem "webmock", "~> 3.11.0"
  gem "json-schema", "2.8.1"
  gem "rails-controller-testing", "1.0.5"
  gem "write_xlsx", "0.86.0"
  gem "browsermob-proxy"
end

group :development, :test do
  gem "pry-byebug"
  gem "pry-rails"
  gem "pry-doc"
  gem "seed-fu", "2.3.9"
  gem "seedbank", "0.5.0"
  gem "rspec-rails", "4.0.1"
  gem "rspec-support", "3.10.0"
  gem "fivemat", "1.3.7"
  gem "rspec-activejob", "0.6.1"
  gem "wisper-rspec", "1.1.0", require: false
  gem "webdrivers", "~> 4.4"
  gem "cucumber", require: false
  gem "spreewald", require: false
  gem "spring"
  gem "spring-commands-rspec"
  gem "guard-rspec"
  gem "guard-shell"
  gem "guard", "2.16.2"
  gem "guard-livereload", "2.5.2"
  gem "terminal-notifier-guard"
  gem "letter_opener"
  gem "rack-reverse-proxy", require: "rack/reverse_proxy"
  gem "parallel_tests", "2.32.0"
  gem "chunky_png", "1.3.15"
  gem "allure-cucumber"
  gem "rswag-specs"
end

NUMBERED_STAGINGS = (2..20).map { |i| "staging-test-#{i}" }.freeze

group *NUMBERED_STAGINGS, :production, :staging, :training, :developing do
  gem "unicorn", require: ENV["RAILS_APPLICATION_SERVER"] != "puma"
  gem "unicorn-rails", require: ENV["RAILS_APPLICATION_SERVER"] != "puma"
  gem "unicorn-worker-killer", require: ENV["RAILS_APPLICATION_SERVER"] != "puma" ? "unicorn/worker_killer" : false
end

group :production, :staging do
  gem "ddtrace", "0.43.0"
end

group *NUMBERED_STAGINGS, :staging, :development, :test do
  gem "factory_bot_rails", "4.11.1"
  gem "clark_faker", path: "gems/clark_faker"
end

gem "contract_price_calculator", path: "gems/contract_price_calculator"

## All gems must be placed before the Comfortable Mexican Sofa gem --------------------------------
gem "comfy_bootstrap_form", "4.0.9"
gem "comfortable_mexican_sofa", git: "https://github.com/comfy/comfortable-mexican-sofa", tag:"v2.0.19"
