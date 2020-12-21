# frozen_string_literal: true

require "rails_helper"

class CreateAdviceReplyTab < PageObject
  def activate_tab
    click_link(Interaction::AdviceReply.model_name.human)
  end

  def assert_visible?
    page.assert_selector("#new_interaction_advice_reply")
  end
end
