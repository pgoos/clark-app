require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class InquiryDetailsPage < PageObject
  include FeatureHelpers

  # Matching
  def expect_variant_title
    expect(find('.capybara-inquiry-row-info').text).to eq("#{I18n.t('manager.inquiries.show.company.upload_title')}")
  end

  def expect_no_variant_title
    expect(find('.capybara-inquiry-row-info').text).to_not eq("#{I18n.t('manager.inquiries.show.company.upload_title')}")
  end

  def expect_two_three_days_title
    expect(find('.capybara-inquiry-row-info').text).to eq("#{I18n.t('manager.inquiries.show.company.upload_response_time')}")
  end

  def expect_no_waiting_time
    page.assert_no_selector('.capybara-inquiry-progress-bar')
  end

  def expect_waiting_time
    page.assert_selector('.capybara-inquiry-progress-bar')
  end

  def expect_no_expert_details
    page.assert_no_selector('.manager__inquiry__header__blacklist-tips__message__wrapper')
  end

  def expect_expert_details
    page.assert_selector('.manager__inquiry__header__blacklist-tips__message__wrapper')
  end

  def expect_no_waiting_time_descr
    page.assert_no_selector('.manager__inquiry__body__waitingtime')
  end
  def expect_waiting_time_descr
    page.assert_selector('.manager__inquiry__body__waitingtime')
  end

  def expect_varient_doc_upload_btn
    page.assert_selector('.manager__inquiry__header__blacklist-tips__message__ctas--variant')
  end
  def expect_no_varient_doc_upload_btn
    page.assert_no_selector('.manager__inquiry__header__blacklist-tips__message__ctas--variant')
  end

  def expect_lovely_infographic
    page.assert_selector('.manager__inquiry__infographic')
  end
  def expect_no_lovely_infographic
    page.assert_no_selector('.manager__inquiry__infographic')
  end

  def expect_whitelist_truck
    page.assert_selector('.manager__inquiry__infographic__graphic__truck--whitelist')
  end
  def expect_no_whitelist_truck
    page.assert_no_selector('.manager__inquiry__infographic__graphic__truck--whitelist')
  end

  def expect_no_accept_clark_waiting_time_link
    page.assert_no_selector('.manager__inquiry__infographic-info__cta')
  end
  def expect_accept_clark_waiting_time_link
    page.assert_selector('.manager__inquiry__infographic-info__cta')
  end

  def expect_document_uploaded_text
    expect(find('.manager__inquiry__header__document-uploaded').text).to eq("#{I18n.t('manager.inquiries.show.info.uploaded')}")
  end

  def expect_pickup_service_active_text
    expect(find('.manager__inquiry__header__document-uploaded').text).to eq("#{I18n.t('manager.inquiries.show.info.pickupservice_active')}")
  end

  def expect_cancel_inq_link
    page.assert_selector('.manager__inquiry__body__abort')
  end

  def open_the_upload
    find('.upload_document_button').click
    find('.manadate-inquiry-document-upload-trigger').click
  end

  def expect_new_document
    page.assert_selector('.manager__inquiry__header__document-uploaded')
  end

  def expect_standard_elements(company, inquiry)
    page.assert_selector(".manager__inquiry__header", visible: true)
    expect(find(".manager__inquiry__header__main__company-name").text).to eq(company.name)
    expect(find(".manager__inquiry__header__main__logo-container__logo")["src"]).to match(inquiry.company.logo.url)
    page.assert_selector(".capybara-inquiry-icon-whitelist")
    page.assert_selector(".manager__inquiry__body__abort")
    page.assert_selector(".clarkordion__item__content__rating", visible: :all)
  end

  def expect_ratings
    page.assert_selector(".clarkordion__item__content__rating")
  end

  def expect_no_ratings
    expect(page).not_to have_selector('.clarkordion__item__content__rating')
  end

  def expect_shows_company_logo(company)
    expect(find(".manager__inquiry__header__main__logo-container__logo")["src"]).to match(company.logo.url)
  end

  def expect_shows_category_name(name)
    expect(find('.manager__inquiry__header__main__category-name').text).to include(word_hypen(name))
  end

  def expect_document_upload
    expect(find('.upload_document_button').text).to eq("#{I18n.t('manager.inquiries.inquiry.document_upload')}")
  end

  def expect_no_document_upload
    expect(page).not_to have_selector('.upload_document_button')
  end

  def expect_document_uploaded_text
    page.assert_selector('.manager__inquiry__header__document-uploaded')
  end

  def expect_no_pickup_service
    expect(page).not_to have_selector('.manager__inquiry__infographic')
  end

  def expect_expert_tips
    page.assert_selector('.clarkordion__item--tips')
  end

  def expect_blacklist
    page.assert_selector('.capybara-inquiry-icon-blacklist')
  end


  # ----------------
  # Page interactions
  #-----------------

  def initialize(locale = I18n.locale)
    @path_to_page_root = "/#{locale}/app/manager/inquiries/"
    @emberHelper = EmberHelper.new
  end

  def visit_page id
    visit "/#{locale}/app/manager/inquiries/#{id}"
    Capybara.current_session.execute_script "window.localStorage.setItem('waitingtime_satisfaction', false);"
  end

  def visit_page_with_category(id, ident)
    visit "/#{locale}/app/manager/inquiries/#{id}?category=#{ident}"
    Capybara.current_session.execute_script "window.localStorage.setItem('waitingtime_satisfaction', false);"
  end

  def navigate_click(classname, location)
    btn = find(classname)
    @emberHelper.ember_transition_click btn
    expect(current_path).to eq("/#{locale}/app/#{location}")
  end

  def click_accept_waiting_time
    find('.manager__inquiry__infographic-info__cta').click
  end

end
