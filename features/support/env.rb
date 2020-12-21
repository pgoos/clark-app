# frozen_string_literal: true

require "capybara/dsl"
require "capybara/rspec"
require "clark_faker"
require "cucumber"
require "cucumber/formatter/unicode"
require "mobility" # required for ".presence" method usage
require "spreewald_support/tolerance_for_selenium_sync_issues" # required for "patiently" method usage

require_relative "allure_utils.rb"

# Capybara configurations & extensions ---------------------------------------------------------------------------------

World(Capybara::DSL) # required for ToleranceForSeleniumSyncIssues#patiently usage
Capybara.server_port = 3001

# soft hyphen handling [https://en.wikipedia.org/wiki/Soft_hyphen]

Capybara::Node::Element.class_eval do
  def shy_normalized_text(type=nil, normalize_ws: false)
    text(type, normalize_ws: normalize_ws).delete("­")
  end
end

Capybara.modify_selector(:css) do
  node_filter(:shy_normalized_text) { |node, text| node.shy_normalized_text(:all) == text }
  node_filter(:starts_with_shy_normalized_text) { |node, text| node.shy_normalized_text(:all).start_with?(text) }
end

# Allure <-> Cucumber compatibility ------------------------------------------------------------------------------------

Cucumber::Core::Test::Step.module_eval do
  def name
    return text if self.text == "Before hook"
    return text if self.text == "After hook"
    "#{source.last.keyword}#{text}"
  end
end

# Global Teardown hooks ------------------------------------------------------------------------------------------------

at_exit do
  AllureUtils.create_env_properties_file
  AllureUtils.copy_categories_json_file
  Proxy::BrowserUpProxy.tear_down
end
