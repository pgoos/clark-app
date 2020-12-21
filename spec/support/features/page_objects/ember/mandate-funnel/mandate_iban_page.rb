require './spec/support/features/page_objects/page_object'

class MandateIbanPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @path_to_page = "/#{locale}/app/mandate/iban"
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_page
  end

  def expect_iban_page
    page.document.synchronize do
      page.assert_selector('.mandate-iban__container')
      # find('.btn-primary').click
      page.assert_current_path(@path_to_page)
    end
    # find('.btn-primary')
  end
end
