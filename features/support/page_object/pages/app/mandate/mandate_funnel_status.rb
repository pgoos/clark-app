# frozen_string_literal: true

require_relative "../../../components/header.rb"
require_relative "../../../components/label.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/status
  class MandateFunnelStatus
    include Page
    include Components::Label
    include Components::Header

    # Page specific methods --------------------------------------------------------------------------------------------

    # Method asserts list of registration steps on mandate status page
    # @param table [Cucumber::Ast::Table] table of expected steps
    def assert_registration_steps(table)
      elements = find("ul.cucumber-mandate-intro-list").all("li").map(&:text)
      expect(elements).to eq(table.rows.flatten)
    end

    private

    # extend Components::Header ----------------------------------------------------------------------------------------

    # Asserts page header presence (the header is hidden in mobile view)
    def assert_app_page_header_is_visible
      expect(page).to have_css(".cucumber_header") if TestContextManager.instance.desktop_browser?
    end
  end
end
