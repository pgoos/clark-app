# frozen_string_literal: true

require "allure-cucumber"
require "capybara/rspec"
require "cucumber"

module Helpers
  # All methods needed for better reporting in case of failures
  module ReportingHelper
    module_function

    # captures a screenshot of browser
    def take_screenshot(scenario)
      timestamp = Time.now.strftime("%Y-%m-%d-%H_%M_%S").to_s
      screenshot_name = "screenshot-#{scenario.name}-#{timestamp}.png"
      screenshot_path = "#{Helpers::OSHelper.file_path('tmp', 'smoke_tests', 'failure_screenshots')}/#{screenshot_name}"
      Capybara.page.save_screenshot(screenshot_path, full: true)
      Allure.add_attachment(name: "failure screenshot",
                            source: File.open(screenshot_path),
                            type: Allure::ContentType::PNG,
                            test_case: true)
    end

    # captures browser logs
    def capture_browser_logs
      errors  = collect_errors
      return if errors.none?
      message = errors.join("\n\n")

      # writes console errors to a log file
      log_file_path = Helpers::OSHelper.file_path("tmp", "smoke_tests", "console_logs", "js_errors.log")
      FileUtils.mkdir_p(File.dirname(log_file_path)) unless File.directory?(File.dirname(log_file_path))

      logging_destination = if !ENV["RAILS_LOG_TO_STDOUT"].nil? && ENV["RAILS_LOG_TO_STDOUT"].to_s == "true"
                              STDOUT
                            else
                              log_file_path
                            end

      logger = Logger.new(logging_destination)
      logger.error(message)
    end

    def collect_errors
      Capybara.page.driver.browser.manage.logs.get(:browser)
              .select { |e| e.level == "SEVERE" && !e.message.nil? && !e.message.empty? }
              .map(&:message)
              .to_a
    end

    # Starts capturing traffic to HAR log
    # need proxy to be running, otherwise nothing will be captured
    # @scenario current scenario
    def start_capturing_traffic(scenario)
      Proxy::BrowserUpProxy.create_new_har(har_name: scenario.name)
    end

    # Saves the captured traffic to HAR file
    # requires HAR log to be created before saving
    def save_captured_traffic_to_file
      har_dir_path = Helpers::OSHelper.file_path("tmp", "smoke_tests", "har_files")
      FileUtils.mkdir_p(har_dir_path)
      Proxy::BrowserUpProxy.save_har_to_file!(har_dir_path)
    end
  end
end
