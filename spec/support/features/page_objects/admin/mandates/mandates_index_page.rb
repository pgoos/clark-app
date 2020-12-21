# frozen_string_literal: true

require "rails_helper"

class MandatesIndexPage < PageObject
  include FeatureHelpers

  def initialize(locale=I18n.locale)
    @locale = locale
    @path = admin_mandates_path(locale: @locale)
  end

  def go
    visit(@path)
    page.assert_current_path(@path)
    assert_selector("body.c-admin-mandates.a-index")
  end

end
