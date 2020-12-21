require './spec/support/features/page_objects/page_object'

class WizardConfirmingPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_confirming_page = polymorphic_path([:confirming, :account, :wizard], locale: locale)
    @form_action_confirming = @path_to_confirming_page
    @path_to_thank_you_page = polymorphic_path([:finished, :account, :wizard], locale: locale)
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_confirming_page
  end

  def click_next
    click_button(I18n.t('next'))
  end

  def submit_form
    click_button(I18n.t('finish'))
  end

  def fill_form
    # Let the JS kick in
    # Timeout.timeout(Capybara.default_wait_time) { loop until page.evaluate_script('typeof(window.jQuery)') == 'function' }

    # Have to show the inputs as capybara freaks out when working with things it cant see
    page.execute_script("$('input').show();")
    # Will also set confirmed because of JS attached to it
    page.find('#mandate_tos_accepted').set(true)
  end

  def sign_canvas
    # Let the JS kick in
    # Timeout.timeout(Capybara.default_wait_time) { loop until page.evaluate_script('typeof(window.jQuery)') == 'function' }

    execute_script("$('[sketch]').scope().$apply(function(){ $('[sketch]').scope().$emit('signatureReady', $('[sketch] canvas')[0].toDataURL()) });")
  end

  def goto_infos
    click_link(I18n.t('account.wizards.confirming.get_info'))
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_failure
    expect(page).to have_css('.ig__error-msg') # expect an error message on the checkboxes (only input that can get this class)
    expect(page).to have_xpath("//form[@action='#{@form_action_confirming}']") # expect confirming form
    expect(current_path).to eq(@form_action_confirming)
  end

  def expect_success
    expect(page).not_to have_css('p.page-header__flash--failure') # expect no error flash message
    expect(current_path).to eq(@path_to_thank_you_page)
  end

end
