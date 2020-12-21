require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class OfferDetailsPageObject < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
  end

  def see_offer_by_id(offer_id)
    page.assert_current_path("/#{locale}/app/offer/#{offer_id}")
  end

  def visit_page(opportunity)
    page_path = "/#{locale}/app/offer/#{opportunity.id}"
    visit(page_path)
    page.assert_current_path(page_path)
    sleep 1
  end

end


