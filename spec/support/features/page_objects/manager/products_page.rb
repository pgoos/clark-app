require './spec/support/features/page_objects/page_object'

class ProductsPage < PageObject
  attr_reader :path

  def initialize(locale = I18n.locale)
    @locale = locale
  end

  # ----------------
  # Page interactions
  #-----------------

  def navigate_to_product(product)
    visit polymorphic_path([:manager, product], locale: @locale)
  end
end
