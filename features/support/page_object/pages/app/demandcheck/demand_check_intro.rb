# frozen_string_literal: true

require_relative "../../../components/icon.rb"
require_relative "../../page.rb"

module AppPages
  # de/app/demandcheck/intro
  class DemandCheckIntro
    include Page
    include Components::Icon

    private

    # extend Components::Icon ------------------------------------------------------------------------------------------

    def assert_demandcheck_trust_icons(icons_quantity)
      icons = find(".cucumber-trust-icons").all(".cucumber-trust-icon", visible: true)
      expect(icons.length).to be(icons_quantity)
    end
  end
end
