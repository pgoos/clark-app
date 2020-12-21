# frozen_string_literal: true

require_relative "../../../../components/label.rb"
require_relative "../../../../components/option.rb"
require_relative "../../../page.rb"

module AppPages
  # This abstract class contains methods common for all targeting pages
  class AbstractTargeting
    include Page
    include Components::Label
    include Components::Option

    CATEGORY_SEARCH_INPUT = '.cucumber-category-selection-search-field input[type="text"]'

    private

    # extend Components::Option ----------------------------------------------------------------------------------------

    def select_targeting_option(value, _)
      locators = %w(li[data-id] li.cucumber-targeting-category-list-item li.cucumber-targeting-company-list-item
                    .cucumber-item[data-test-generic-selection-list-item])
      locators.each do |locator|
        return find(locator, shy_normalized_text: value).click if page.has_css?(locator, shy_normalized_text: value)
      end
      raise Capybara::ElementNotFound.new("Can't click on #{value} target option")
    end

    ##
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Move this method to a new page object so it can be used exclusively
    # by the page "offers.request"
    #
    def select_category_option(value, _)
      locators = %w[.cucumber-popular-item .cucumber-item]
      locators.each do |locator|
        return find(locator, text: value).click if page.has_css?(locator, text: value)
      end
      raise Capybara::ElementNotFound.new("Can't click on #{value} target option")
    end

    # extend Components::Input -----------------------------------------------------------------------------------------

    def assert_search_input_field
      expect(page).to have_css(".cucumber-targeting-search-field")
    end

    def enter_value_into_search_input_field(search_term)
      find(".cucumber-category-search-input").native.send_keys(search_term)
      sleep 1
    end

    ##
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Move these two methods to a new page object so it can be used exclusively
    # by the page "offers.request"
    #
    def assert_category_search_input_field
      expect(page).to have_css(CATEGORY_SEARCH_INPUT)
    end

    def enter_value_into_category_search_input_field(search_term)
      find(CATEGORY_SEARCH_INPUT).native.send_keys(search_term)
      sleep 1
    end

    def assert_text_in_search_input_field(value)
      expect(find("input.cucumber-category-search-input").value).to eq(value)
    end
  end
end
