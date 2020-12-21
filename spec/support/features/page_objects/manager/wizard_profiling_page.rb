require './spec/support/features/page_objects/page_object'

class WizardProfilingPage < PageObject

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_profile_page = polymorphic_path([:profiling, :account, :wizard], locale: @locale)
    @form_action_profiling = @path_to_profile_page
    @path_to_confirming_page = polymorphic_path([:confirming, :account, :wizard], locale: @locale)
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_profile_page
  end

  def fill_form_with_gender
    first('.flex__row--medium-column .custom-radio > span').click
    find('.flex__row--medium-column').fill_in 'mandate_first_name', with: 'FirstName'
    find('.flex__row--medium-column').fill_in 'mandate_last_name', with: 'LastName'
    find('.flex__row--medium-column').fill_in 'route', with: 'Sesamstraße'
    find('.flex__row--medium-column').fill_in 'street_number', with: '3'
    find('.flex__row--medium-column').fill_in 'postal_code', with: '12345'
    find('.flex__row--medium-column').fill_in 'locality', with: 'Sesamstadt'

    find('.datepicker.picker').click
    find('li[data-view=year]', match: :first).click
    find('li[data-view=month]', match: :first).click
    find('li[data-view=day]', match: :first).click
  end

  def fill_form

    #first('.flex__row--medium-column .custom-radio > span').click
    find('.flex__row--medium-column').fill_in 'mandate_full_name', with: 'FirstName LastName'
    find('.flex__row--medium-column').fill_in 'route', with: 'Sesamstraße'
    find('.flex__row--medium-column').fill_in 'street_number', with: '3'
    find('.flex__row--medium-column').fill_in 'postal_code', with: '12345'
    find('.flex__row--medium-column').fill_in 'locality', with: 'Sesamstadt'


    #
    # Timeout.timeout(Capybara.default_wait_time) { loop until page.evaluate_script('typeof(window.jQuery)') == 'function' }

    find('.datepicker.picker').click
    find('li[data-view=year]', match: :first).click
    find('li[data-view=month]', match: :first).click
    find('li[data-view=day]', match: :first).click

    # select ISO3166::Country['DE'].translations[@locale.to_s], from: 'mandate_country_code', match: :first
  end

  def fill_form_mobile
    #first('.flex__row--medium-column .custom-radio > span').click
    find('.flex__row--medium-column').fill_in 'mandate_full_name', with: 'FirstName LastName'
    find('.flex__row--medium-column').fill_in 'mandate_birthdate', with: '12.12.1923'
    find('.flex__row--medium-column').fill_in 'route', with: 'Sesamstraße'
    find('.flex__row--medium-column').fill_in 'street_number', with: '3'
    find('.flex__row--medium-column').fill_in 'postal_code', with: '12345'
    find('.flex__row--medium-column').fill_in 'locality', with: 'Sesamstadt'
  end

  def empty_form
    fill_in 'mandate_full_name', with: ''
    fill_in 'mandate[birthdate]', with: ''
    fill_in 'route', with: ''
    fill_in 'street_number', with: ''
    fill_in 'postal_code', with: ''
    fill_in 'locality', with: ''
  end

  def fill_birthdate(datestring)
    find('.flex__row--medium-column').fill_in 'mandate_birthdate', with: datestring
  end

  def submit_form
    click_button('Weiter')
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_failure
    expect(page).to have_css('.ig__error-msg')
    expect(page).to have_xpath("//form[@action='#{@form_action_profiling}']") # expect profiling form
    expect(current_path).to eq(@form_action_profiling)
  end

  def expect_success
    expect(page).not_to have_css('.page-header__flash--failure')
    expect(page).to have_xpath("//form[@action='#{@path_to_confirming_page}']") # expect to see signing form
    expect(current_path).to eq(@path_to_confirming_page)
  end

end
