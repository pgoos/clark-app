# frozen_string_literal: true

require "capybara-screenshot"
require "selenium-webdriver"
require "webdrivers" if Gem.loaded_specs.key?("webdrivers") # Disable webdrivers in Jenkins

require_relative "test_context_manager.rb"
require_relative "proxy/browser_up_proxy.rb"

# TODO: implement DriverBuilder [JCLARK-52427] lets do it please

Capybara.default_max_wait_time = 30

USER_AGENT = "--user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko) "\
"Chrome/67.0.3396.99 Safari/537.36, Cucumber 2154a52c'"

selenium_hub_endpoint = "http://#{TestContextManager.instance.selenium_hub_ip}:4444/wd/hub"
chrome_options = { args:
                       ["window-size=2000,2000",
                        "ignore-certificate-errors",
                        "allow-insecure-localhost",
                        "incognito",
                        "disable-infobars",
                        USER_AGENT] }

selenium_proxy = nil
if TestContextManager.instance.enabled_proxy
  begin
    selenium_proxy = Proxy::BrowserUpProxy.create_proxy.get_proxy_address(:ssl, :http)
  rescue StandardError
    # do nothing. Add logging here describing what happened
  end
end

# Local drivers --------------------------------------------------------------------------------------------------------

Capybara.register_driver :headless_chrome do |app|
  options = { args:
                  ["headless",
                   "disable-gpu",
                   "ignore-certificate-errors",
                   "allow-insecure-localhost",
                   "window-size=2000,2000",
                   "incognito",
                   "disable-infobars",
                   "--enable-features=NetworkService,NetworkServiceInProcess",
                   USER_AGENT] }

  if ENV["CHROME_WITHOUT_SANDBOX"] == "true"
    options[:args].push("no-sandbox")
  end

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    "goog:chromeOptions": options,
    proxy: selenium_proxy,
    loggingPrefs: { browser: "ALL" }
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    "goog:chromeOptions": chrome_options,
    proxy: selenium_proxy,
    loggingPrefs: { browser: "ALL" }
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :chrome_iphone_x do |app|
  download_directory = Helpers::OSHelper.file_path("tmp", "smoke_tests", "downloads")
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    proxy: selenium_proxy,
    "goog:chromeOptions": {
      args: %w[incognito disable-infobars ignore-certificate-errors allow-insecure-localhost],
      prefs: { plugins: { always_open_pdf_externally: true },
               savefile: { default_directory: download_directory },
               download: { prompt_for_download: false, default_directory: download_directory } },
      mobileEmulation: {
        deviceMetrics: { width: 375, height: 812, pixelRatio: 3.0 },
        userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) "\
                    "Version/11.0 Mobile/15A372 Safari/604.1, Cucumber 2154a52c"
      }
    }
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :headless_chrome_iphone_x do |app|

  args = %w[headless incognito disable-infobars ignore-certificate-errors allow-insecure-localhost]

  if ENV["CHROME_WITHOUT_SANDBOX"] == "true"
    args.push("no-sandbox")
  end

  download_directory = Helpers::OSHelper.file_path("tmp", "smoke_tests", "downloads")
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    proxy: selenium_proxy,
    "goog:chromeOptions": { args: args,
                            prefs: { plugins: { always_open_pdf_externally: true },
                                     savefile: { default_directory: download_directory },
                                     download: {
                                       prompt_for_download: false,
                                         default_directory: download_directory
                                     } },
                         mobileEmulation: {
                           deviceMetrics: { width: 375, height: 812, pixelRatio: 3.0 },
                           userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 "\
                           "(KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1, Cucumber 2154a52c"
                         } }
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

# Remote drivers -------------------------------------------------------------------------------------------------------

Capybara.register_driver :remote_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: chrome_options,
    proxy: selenium_proxy,
    loggingPrefs: { browser: "ALL" }
  )
  Capybara::Selenium::Driver.new(app, browser: :remote, url: selenium_hub_endpoint, desired_capabilities: capabilities)
end

Capybara.register_driver :remote_firefox do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile["general.useragent.override"] = USER_AGENT
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(
    firefox_profile: profile
  )
  Capybara::Selenium::Driver.new(app, browser: :remote, url: selenium_hub_endpoint, desired_capabilities: capabilities)
end

# Proxy doesn't work with Internet Explorer yet, need to find out how to ignore untrusted certificates warning
Capybara.register_driver :remote_ie do |app|
  Capybara::Selenium::Driver.new(app, browser: :remote, url: selenium_hub_endpoint)
end

Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

# Select Driver --------------------------------------------------------------------------------------------------------

if %I[remote_chrome remote_firefox remote_ie].include?(TestContextManager.instance.driver) && TestContextManager.instance.selenium_hub_ip.nil?
  raise ArgumentError.new("SELENIUM_HUB_IP arg should be provided for the remote drivers")
end

Capybara.default_driver = TestContextManager.instance.driver
Capybara.javascript_driver = TestContextManager.instance.driver
