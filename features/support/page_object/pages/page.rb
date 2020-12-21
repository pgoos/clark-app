# frozen_string_literal: true

require "capybara/dsl"
require "rspec"

require_relative "../components/button.rb"
require_relative "../components/input.rb"
require_relative "../components/link.rb"
require_relative "../components/menu.rb"
require_relative "../components/meta_information.rb"
require_relative "../components/text.rb"

# This module should be included into every Page Object class
# Contains imports of required 3rd party modules and several basics Components
# DO NOT implement any method inside this module
# DO NOT include components with dispatcher only methods without any cross shared methods
module Page
  include Capybara::DSL
  include RSpec::Matchers
  include Components::Button
  include Components::Input
  include Components::Link
  include Components::Menu
  include Components::MetaInformation
  include Components::Text
end
