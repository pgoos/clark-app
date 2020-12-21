# frozen_string_literal: true

require "rails_helper"

class MandateSearchRight < PageObject
  def initialize(locale=I18n.locale)
    @locale = locale
  end

  def assert_visible
    right_column_content.assert_selector(:xpath, xpath_form_selector)
  end

  def search_by_insurance_product_number(product_number)
    fill_in("Versicherungsnummer", with: product_number)
    submit_form
  end

  private

  def right_column_content
    @right_column_content ||= find(".right-column-content")
  end

  def xpath_form_selector
    ".//form[contains(@action, 'mandates')]"
  end

  def form
    right_column_content.find(:xpath, xpath_form_selector)
  end

  def submit_form
    form.find(:xpath, ".//input[contains(@type, 'submit')]").click
  end
end
