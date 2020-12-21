# frozen_string_literal: true

require_relative "../../components/checkbox.rb"
require_relative "../../components/modal.rb"
require_relative "../page"

module CMSPages
  # /sterbegeldversicherung
  class Sterbegeldversicherung
    include Page
    include Components::Modal
    include Components::Checkbox

    # extend Components::Checkbox --------------------------------------------------------------------------------------

    def select_lead_gen_checkbox
      find("label[class*='input-form-checkbox-container']").click
    end

    def assert_sterbegeldversicherung_modal
      expect(page).to have_css("div[role='dialog']")
    end
  end
end
