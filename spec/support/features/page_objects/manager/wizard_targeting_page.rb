require './spec/support/features/page_objects/page_object'

class WizardTargetingPage < PageObject

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_targeting_page = polymorphic_path([:targeting, :account, :wizard], locale: locale)
    @form_action_targeting = @path_to_targeting_page
    @path_to_profiling_page = polymorphic_path([:profiling, :account, :wizard], locale: locale)
    @form_action_profiling = @path_to_profiling_page
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_targeting_page
  end

  def select_company(company)
    find('li[data-id="' + company.id.to_s + '"]').click
  end

  def submit_form
    click_button('Weiter')
  end

  # ----------------
  # RSpec matcher
  #-----------------

  def expect_disabled
    within('.wizard-select-insurance__progress-btn') do
      submit = find_button("#{I18n.t('next')}")
      expect(submit.disabled?).to eq(true)
    end
  end

  def expect_success
    expect(page).not_to have_css('p.page-header__flash--failure') # expect no error flash message
    expect(page).to have_xpath("//form[@action='#{@form_action_profiling}']") # expect profile form
    expect(current_path).to eq(@path_to_profiling_page)
  end

end
