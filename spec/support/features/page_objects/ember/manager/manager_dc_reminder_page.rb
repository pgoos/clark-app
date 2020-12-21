require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class ManagerDcReminder < PageObject
  include FeatureHelpers


  def initialize(locale = I18n.locale)
    @locale      = locale
    @emberHelper = EmberHelper.new
  end

  def close_modal
    find('.ember-modal__body__close').click
  end

  def modal_shows_up
    page.assert_selector('.ember-modal', visible: true)
  end

  def modal_has_title(text)
    expect(find('.demancheck_reminder__middle__heading').text).to eq(text)
  end

  def modal_has_description(text)
    expect(find('.demancheck_reminder__middle__content').text).to eq(text)
  end

  def modal_not_visible
    page.assert_selector('.ember-modal', visible: false)
  end

  def has_cta(text)
    find_button(text)
  end
end
