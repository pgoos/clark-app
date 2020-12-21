# frozen_string_literal: true

require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/mam
  class MilesAndMoreForm
    include Page

    private

    # extend Components::Input -----------------------------------------------------------------------------------------

    def assert_mamcard_input_field
      expect(page).to have_css("p.cucumber-mam-card-field")
    end
  end
end
