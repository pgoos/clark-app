require './spec/support/features/page_objects/page_object'

class AddInsurancesPage < PageObject

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = polymorphic_path([:targeting, :account, :mandate], locale: locale)
    @form_action_profiling = polymorphic_path([:account, :wizard], locale: @locale)

  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
  end

  def select_company(company)
    find('li[data-id="' + company.id.to_s + '"]').click
  end

  def check_class(company, class_name)
    expect(page).to have_css('li[data-id="' + company.id.to_s + '"]'+ class_name)
  end

  def check_not_class(company, class_name)
    expect(page).not_to have_css('li[data-id="' + company.id.to_s + '"]'+ class_name)
  end


  def submit_form
    click_button('Hinzufügen')
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_company_present(company)
    expect(page).to have_css('.wizard-select-insurance__companies li[data-id="' + company.id.to_s + '"]')
  end

  def expect_company_selected(company)
    check_class(company, '.wizard-select-insurance__companies__item--selected')
  end

  def expect_company_owned(company)
    check_class(company, '.wizard-select-insurance__companies__item--owned')
  end

  def expect_company_not_selected(company)
    check_not_class(company, '.wizard-select-insurance__companies__item--selected')
    check_not_class(company, '.wizard-select-insurance__companies__item--owned')
  end

  def expect_company_removable(company)
    check_class(company, '.wizard-select-insurance__companies__item--selected')
    select_company(company)
    check_not_class(company, '.wizard-select-insurance__companies__item--selected')
    select_company(company)
  end

  def expect_company_not_removable(company)
    # Select it and click it, should still haver owned class
    select_company(company)
    check_class(company, '.wizard-select-insurance__companies__item--owned')
    select_company(company)
    check_class(company, '.wizard-select-insurance__companies__item--owned')
  end

end
