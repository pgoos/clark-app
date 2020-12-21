# frozen_string_literal: true

# Contains steps definitions for Features management

Given(/app feature "([^"]*)" is on/) do |key|
  ApiFacade.new.automation_helpers.switch_setting_app_feature(key, true)
end

Given(/app feature "([^"]*)" is off/) do |key|
  ApiFacade.new.automation_helpers.switch_setting_app_feature(key, false)
end

Given(/feature switch "([^"]*)" is on/) do |key|
  ApiFacade.new.automation_helpers.switch_feature(key, true)
end

Given(/feature switch "([^"]*)" is off/) do |key|
  ApiFacade.new.automation_helpers.switch_feature(key, false)
end
