require './spec/support/features/page_objects/page_object'

class NPSModelPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_cockpit = "/#{locale}/app/manager"
  end

  # ----------------
  # Page interactions
  #-----------------

  def visit_page
    visit @path_to_cockpit
    # allow for the skeleton view
    page.assert_selector(".capybara-contracts-list")
  end

  def nps_page_has_correct_element
    page.assert_selector('.ember-modal__body__content', visible: true)
    page.assert_selector('.ember-modal__body__content__title')
    expect(find('.ember-modal__body__content__title').text).to eq("Jhon, wie wahrscheinlich ist es, dass du Clark einem Freund oder Kollegen weiterempfehlen wirst?")
  end

  def select_nps_score_less_than_six
    find('.circle-bar__item:nth-child(3)').click()
  end

  def select_nps_score_greater_than_seven
    find('.circle-bar__item:nth-child(8)').click()
  end

  def click_weiter
    page.assert_selector('.net-promoter-score__cta')
    find('.net-promoter-score__cta').click()
  end


  def nps_comment_has_correct_element
    expect(find('.ember-modal__body__content__title').text).to eq("Vielen Dank für deine Bewertung!")
    expect(find('.net-promoter-score__comment__sub-heading').text).to eq("Gib uns kurz Feedback, warum du Clark nicht weiterempfehlen wirst.")
    find('.net-promoter-score__comment__input-comment-field')
  end

  def expect_no_modal
    page.assert_no_selector('.ember-modal__body__content__title')
  end

  # Just so we can also check what is NOT there ;)
  def expect_main_cta
    page.assert_selector('.manager__cockpit__add-insurances-cta__btn__large-text')
  end

  def nps_comment_enables_button
    find('.net-promoter-score__comment__input-comment-field').set("This is a comment")
    page.assert_selector('.net-promoter-score__cta')
  end

  def rate_us_popup_is_visible
    page.assert_selector('#rateUsModal')
  end

  def feedback_popup_is_visible
    page.assert_selector('#feedbackModal')
  end

  def select_rating_less_than_three
    find('.rate-us-modal__stars__star:nth-child(3)').click()
  end

  def click_submit_rating
    find('.rate-us__cta').click()
  end

  def clear_session_storage
    page.execute_script "window.sessionStorage.clear();"
  end

end
