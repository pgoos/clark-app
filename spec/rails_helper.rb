# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require "spec_helper"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "clark_faker"
require "money-rails/test_helpers"
require "support/test_host"
require "support/features/feature_helpers"
require "support/features/browser_helpers"
require "support/api_spec_helper"
require "support/appointment_date_helpers"
require "support/situation_personas"
require "support/controller_helpers"
require "support/shoulda_matchers"
require "support/counter_matcher"
require "support/audit_helpers"
require "rspec/active_job"
require "wisper/rspec/matchers"
require "selenium/webdriver"
require "support/double_helpers"
require "support/db_query_counter"
require "rspec/retry"
require "webmock/rspec"

Dir["./spec/support/shared_examples/**/*.rb"].sort.each { |f| require f }

FIXTURE_DIR = "spec/fixtures/files"

# This class is used to remember the file path and the context of a particular test execution, since by now we
# for example need to decide after the execution of a spec file, if we need to truncate tables. The latter is
# necessary for API tests, because our DatabaseCleaner strategy is currently wrong here. It is
# set to :transaction, although it needs to be :truncation.
class Remember
  cattr_accessor :file_path
  cattr_accessor :running_context
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

Capybara.default_max_wait_time = 10

Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {args: %w[auto-open-devtools-for-tabs disable-gpu window-size=1800,1200]}
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :headless_chrome do |app|
  chrome_options = %w[headless disable-gpu window-size=1800,1200 incognito disable-infobars]

  if ENV["CHROME_WITHOUT_SANDBOX"] == "true"
    chrome_options.push("no-sandbox")
  end

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    "goog:chromeOptions": {args: chrome_options},
    loggingPrefs: {browser: "ALL"}
  )

  selenium_options = {
    browser: :chrome, desired_capabilities: capabilities
  }

  if ENV["CHROMEDRIVER_VERBOSE"] == "true"
    selenium_options[:driver_opts] = {
      verbose: true,
      log_path: Rails.root.join("log", "chromedriver#{ENV['TEST_ENV_NUMBER']}.log")
    }
  end

  Capybara::Selenium::Driver.new(app, selenium_options)
end

# Add support for Headless Chrome screenshots.
Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.register_driver :headless_chrome_ios_app do |app|
  args = []
  args << "headless"
  args << "disable-gpu"
  args << "user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 9_2 like Mac OS X) \
AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13C75 \
| Clark/2.0.0(Build: 333) (Device: x86_64 iOS: 2.0.0)"
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {args: args}
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :headless_chrome_android_app do |app|
  args = []
  args << "headless"
  args << "disable-gpu"
  args << "user-agent=Mozilla/5.0 (Linux; Android 5.0.2; Android SDK built for x86 Build/LSY66K) \
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 \
Crosswalk/15.44.384.12 Mobile Safari/537.36 Clark/2.0.0"
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {args: args}
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :headless_chrome_mobile_ios_browser do |app|
  args = []
  args << "headless"
  args << "disable-gpu"
  args << "user-agent=Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) \
AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {args: args}
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.javascript_driver = :headless_chrome
# For Visual Debugging:
# Capybara.javascript_driver = :chrome

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.

Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |file| require file }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

include BrowserHelpers

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  WebMock.disable!
end

RSpec.configure do |config|
  # INCLUDES #######################################################################################
  config.include Shoulda::Callback::Matchers::ActiveModel
  config.include FeatureHelpers, type: :feature
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers
  config.include ControllerHelpers, type: :controller
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: %r{spec/api}
  config.include ApiSpecHelper, type: :request, file_path: %r{spec/api}
  config.include FactoryBot::Syntax::Methods
  config.include RSpec::ActiveJob
  config.include ActionView::TestCase::Behavior, type: :presenter
  config.include AdminSpecHelpers
  config.include Wisper::RSpec::BroadcastMatcher
  config.include DoubleHelpers
  config.include ShouldaMatcherFixes
  config.include AuditHelpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include StateMachinesRspec::Matchers
  # config.include ActiveSupport::Testing::SetupAndTeardown, type: :presenter

  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # run retry only on features
  config.around :each, :js do |ex|
    ex.run_with_retry retry: 3
  end

  # SETTINGS #######################################################################################
  config.infer_spec_type_from_file_location!

  # SHOWS THE TOP 10 SLOWEST SPECS
  config.profile_examples = true

  # Prevent factories from using Class instead of Symbol
  FactoryBot.allow_class_lookup = false

  # Run the specs in random order
  # TODO: Uncomment this and make the tests run in random order
  # Current failings (as of 25.04.2016):
  #  - admin/(users|leads)_controller - (un)-subscribe/-confirm fails when run as the first tests
  #  - tests requiring a CMS page to be present fail when they are executed at certain points
  #
  # config.order = :random

  # This config option will be enabled by default on RSpec 4, but for reasons of backwards
  # compatibility, you have to set it on RSpec 3.
  # It causes the host group and examples to inherit metadata from the shared context.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # BEFORE SUITE ###################################################################################
  config.before(:suite) do
    Settings.reload!
    Warden.test_mode!

    # Load classification
    Domain::Classification::QualityForCustomerClassifier.load_classification
  end

  # BEFORE EACH ####################################################################################
  config.before do |_example|
    Capybara.server_host = TestHost.test_host
    Capybara.app_host    = nil
    Capybara.server_port = TestHost.test_port + ENV["TEST_ENV_NUMBER"].to_i

    if ENV["CAPYBARA_LOGS"].present?
      CAPYBARA_LOGGER.info("New Description --- #{_example.description}")
      CAPYBARA_LOGGER.info("New Location --- #{_example.location}")
    end

    I18n.locale = :de

    # Enable audit directly by metatag
    disable_audit unless _example.metadata.key?(:business_events)
    WebMock.enable! if _example.metadata.key?(:vcr)

    @records_count = ApplicationRecord.descendants.inject({}) do |res, m|
      res.merge!(m => m.count)
    end if ENV["PERSISTENCE_STATS"]
  end

  config.before(:each, type: :feature) do |example|
    if !example.file_path.include?("/feature_tests/") && ENV["ENABLE_TRACKING_SCRIPTS"] != "true"
      Capybara.current_session.visit("/de/tracking/opt-out")
    end
  end

  # config.before(:each, type: :presenter) do
  #   setup_with_controller  # this is necessary because otherwise @controller is nil, but why?
  # end

  # AFTER EACH #####################################################################################
  config.after do
    WebMock.disable!

    Timecop.return
    Warden.test_reset!

    @records_count.each do |model, count_before|
      count_now = model.count
      next if count_before >= count_now
      info = "#{count_now - count_before} #{model.to_s.pluralize}"
      Rails.logger.info(info)
      puts(info)
    end if ENV["PERSISTENCE_STATS"]
  end

  # BROWSER SPECS

  config.before(:example, browser: true) do
    next if keep_cookie_banner

    Capybara.current_session.visit("/404")

    driver = Capybara.current_session.driver
    case driver
    when Capybara::Selenium::Driver
      browser = driver.browser
      browser.manage.add_cookie(name: PrivacySetting::BANNER_VISIBILITY_COOKIE, value: "true")
      browser.manage.add_cookie(name: PrivacySetting::MARKETING_TRACKING_COOKIE, value: "true")
      browser.manage.add_cookie(name: PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP, value: Time.current.to_s)
    else
      if driver.browser.respond_to?(:set_cookie)
        cookie_string = "#{PrivacySetting::BANNER_VISIBILITY_COOKIE}=true; " \
        "#{PrivacySetting::MARKETING_TRACKING_COOKIE}=true; " \
        "#{PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP}=#{Time.current}"

        driver.browser.set_cookie(cookie_string)
      else
        driver.cookies.add(PrivacySetting::BANNER_VISIBILITY_COOKIE, "true")
        driver.cookies.add(PrivacySetting::MARKETING_TRACKING_COOKIE, "true")
        driver.cookies.add(PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP, Time.current.to_s)
      end
    end
  end

  config.include_context "Features Helpers", browser: true
end
