require './spec/support/features/page_objects/page_object'

class NewsletterPage < PageObject
  attr_reader :path

  def initialize(locale = I18n.locale)
    @locale = locale
  end

  # ----------------
  # Page interactions
  #-----------------

  # Navigate to the homepage
  def navigate_home
    visit root_path(locale: @locale)
  end

  def navigate_to_non_blackisted_page
    visit '/de/ueber-uns'
  end

end
