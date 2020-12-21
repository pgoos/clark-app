# frozen_string_literal: true

# TODO: Delete this module
module Helpers
  module MobileBrowserHelper
    INSURANCE_TYPE_TABS = %w[things health retirement].freeze

    module_function

    def switch_to_demandcheck_tab_if_needed(category)
      return nil unless TestContextManager.instance.mobile_browser?
      url = URI.parse(Capybara.current_session.current_url)
      return nil unless url.to_s.include?(Repository::PathTable["recommendations"])
      index = INSURANCE_TYPE_TABS.index(Repository::InsuranceCategories[category]) + 1
      switch_to_slider_section(index)
    end

    def switch_to_slider_section(index)
      return nil unless TestContextManager.instance.mobile_browser?
      Capybara.current_session.find("div.swiper-pagination span:nth-child(#{index})").click
      sleep 2 # wait for animation
    end

    def open_section_if_required(section_name)
      return nil unless TestContextManager.instance.mobile_browser?
      url = URI.parse(Capybara.current_session.current_url)
      return nil unless url.to_s.include? "/de/app/manager/inquiries/"
      Capybara.current_session.find(".clarkordion__item__header", text: section_name).click
    end
  end
end
