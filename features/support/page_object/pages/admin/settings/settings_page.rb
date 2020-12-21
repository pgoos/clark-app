# frozen_string_literal: true

require_relative "../../page.rb"

class SettingsPage
  include Page

  def turn_off_feature_switch(feature)
    table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
    feature_switch = table_helper.get_button_by_text_in_row(1, 0, feature)
    feature_switch.click unless feature_switch.text == "switched off"
  end

  def turn_on_feature_switch(feature)
    table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
    feature_switch = table_helper.get_button_by_text_in_row(1, 0, feature)
    feature_switch.click unless feature_switch.text == "running"
  end
end
