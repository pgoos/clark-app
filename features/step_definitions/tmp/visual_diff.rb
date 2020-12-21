# frozen_string_literal: true

# Temp solution, Just to store proof of concept results.
# TODO: refactor before usage. [reduce hardcode, move code to helpers, etc]
# TODO: check if it's still actual

require "tmpdir"

# Constants

STAGING_HOST = "https://staging.clark.de"
THRESHOLD = 0.01 # TODO: find realistic threshold
ERROR_TEMPLATE = "Images (%<path>s) difference percentage expected to be <= %<expected>.4f, but got %<actual>.4f%"
DIFF_IMAGES_PATH = "/tmp/DIFF_TESTING/" # change it so CI can use it (attach artifacts to a build)

Given(/^(?:user|lead|mandate|admin) creates folder for screenshots$/) do
  @screenshots_dir = Dir.mktmpdir("visual_diff_testing_") # change it to, Attach to a build too
end

And(/^(?:user|lead|mandate|admin) takes screenshot with name "([^"]*)"$/) do |name|
  host_name = Capybara.app_host[Capybara.app_host.index(":") + 2..-1]
  screenshot_path = [@screenshots_dir, "/", name, host_name, ".png"].join
  Capybara.page.save_screenshot(screenshot_path, full: true)
end

Then(/^(?:user|lead|mandate|admin) switches environment to staging$/) do
  Capybara.app_host = STAGING_HOST
end

Then(/^(?:user|lead|mandate|admin) compares screenshots from different environments$/) do
  folder_content(@screenshots_dir).each do |path|
    images = folder_content(path) # improve this methods. Screenshot from staging_1 should always be at 0 place
    diff_percentage = compare_images(images[0], images[1], [DIFF_IMAGES_PATH, File.basename(path) + ".png"].join)
    error_msg = ERROR_TEMPLATE % {path: path, expected: THRESHOLD, actual: diff_percentage}
    expect(diff_percentage).to be <= THRESHOLD, error_msg
  end
end
