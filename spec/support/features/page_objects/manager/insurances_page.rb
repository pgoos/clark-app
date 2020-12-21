require './spec/support/features/page_objects/page_object'

class InsurancesPage < PageObject

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_page = "/#{locale}/app/manager"
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
  end

  # ----------------
  # Page elements
  #-----------------

  def added_companies
    find('.manager__cockpit--bottom')
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_success_confirmed
    expect(page).to have_content(I18n.t('account.wizards.confirming.flash.success_confirmed'))
  end

  def expect_success_unconfirmed
    expect(page).to have_content(I18n.t('account.wizards.confirming.flash.success_unconfirmed'))
  end

  def expect_company_added(company)
    expect(added_companies).to have_content(company.name)
  end

  def expect_company_not_removable(company)
    expect(added_companies).to have_content(company.name)
  end

end
