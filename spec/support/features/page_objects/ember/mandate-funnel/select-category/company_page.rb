require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class SelectCompanyPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/mandate/targeting/company"
    @emberHelper = EmberHelper.new
  end

  # ----------------
  # Page interactions
  #-----------------

  def search_for(query)
    fill_in 'search_input', with: query
  end

  def shows_item(id)
    find('li[data-id="' + id.to_s + '"]', visible: true)
  end

  def click_item(id)
    page.document.synchronize do
      page.assert_selector('.manager__company-select__companies__company--item[data-id="' + id.to_s + '"]')
      find('.manager__company-select__companies__company--item[data-id="' + id.to_s + '"]').click
      find('.btn-primary')
    end
  end

  def click_not_found
    find('li.manager__company-select__companies__company--not-found').click
    page.assert_selector('#addCompanyModal')
  end

  def expect_search_instruction_text(string)
    find(".cucumber-targeting-insurance-intro").assert_text(string, minimum: 1)
  end

  def expect_company_page
    page.assert_selector('.manager__company-select__companies__section')
    page.assert_selector('.manager__company-select__companies__company--item')
  end

  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end

end
