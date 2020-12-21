require './spec/support/features/page_objects/page_object'

class ManageWithClarkPage < PageObject
  attr_reader :path, :missing_company_path

  def initialize(locale = I18n.locale)
    @locale = locale
    @path = polymorphic_path([:manager, :manage_with_clark], locale: @locale)
    @missing_company_path = polymorphic_path([:manager, :manage_with_clark, :missing_insurance], locale: @locale)
  end

  # ----------------
  # Page interactions
  #-----------------

  # Navigate to the start of the manage with clark views
  def navigate
    visit @path
  end

  def navigate_missing_company
    visit @missing_company_path
  end

  def navigate_category
    find('.manage-with-clark__categories__category').click
  end

  def add_company
    find('.manage-with-clark__categories__category').click
    first('.manage-with-clark__companies__company').click
  end

  def add_companies
    find('.manage-with-clark__categories__category').click
    companies = page.all('.manage-with-clark__companies__company')
    companies[0].click
    companies[1].click
  end

end
