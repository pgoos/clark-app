# frozen_string_literal: true

require "rails_helper"

class CreateAdviceTab < PageObject
  def activate_tab
    click_link(Interaction::Advice.model_name.human)
  end

  def assert_visible?
    page.assert_selector("#new_interaction_advice")
  end
end
