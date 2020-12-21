# frozen_string_literal: true

When(/^admin turns on "([^"]*)" feature switch$/) do |feature|
  SettingsPage.new.turn_on_feature_switch(feature)
  Helpers::NavigationHelper.wait_for_resources_downloaded
end

When(/^admin turns off "([^"]*)" feature switch$/) do |feature|
  SettingsPage.new.turn_off_feature_switch(feature)
  Helpers::NavigationHelper.wait_for_resources_downloaded
end
