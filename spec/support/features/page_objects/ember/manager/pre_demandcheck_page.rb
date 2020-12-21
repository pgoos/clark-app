require './spec/support/features/page_objects/page_object'

class PreDemandCheckPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_pre_demandcheck = "/#{locale}/app/demandcheck/intro"
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_pre_demandcheck
  end

  def click_start_bedarfscheck
    click_button('Bedarfscheck starten')
    page.assert_current_path("/#{locale}/app/demandcheck")
  end

end
