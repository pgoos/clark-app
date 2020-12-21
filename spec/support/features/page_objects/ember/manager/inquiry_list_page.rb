require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class InquiryListPage < PageObject
  include FeatureHelpers


  def assert_blacklist_card
    page.assert_selector('.card-list__item--orange')
  end

  def assert_status_text(traslationRoot)
    within(".manager__inquiries-list__inquiry__descr_wrapper__inner--orange-text") do
      assert_text("#{I18n.t(traslationRoot)}")
    end
  end

  def assert_whitelist_card
    page.assert_no_selector('.card-list__item--orange')
  end

  def assert_no_category
    page.assert_no_selector('.card-list__item--orange')
  end

  def assert_inquiry_with_category(categoryName)
    expect(find('.manager__inquiries-list').text).to include(word_hypen(categoryName))
  end

  def expect_arrow(amount)
    page.assert_selector('.arrow-icon', count: amount)
  end

  def expect_no_arrow
    page.assert_no_selector('.arrow-icon')
  end

  def expect_to_have_count_of_inquiry_cards(count)
    page.assert_selector(".capybara-inquiry-card", count: count)
  end

  def expect_pickup_service_active_text
    expect(find('.capybara-inquiry-card').text).to include("#{I18n.t('manager.inquiries.inquiry.pickupservice_active')}")
  end

  def expect_blacklist_old_status_text
    expect(find('.capybara-inquiry-card').text).to include("#{I18n.t('manager.inquiries.inquiry.blacklisted.more_information')}")
  end

  def expect_whitelist_old_status_text
    expect(find('.capybara-inquiry-card').text).to include("#{I18n.t('manager.inquiries.inquiry.pending')}")
  end

  def expect_card_status(state, id)
    state_trans = "manager.inquiries.inquiry.#{state}"
    expect(find(".capybara-inquiry-card#{id}").text).to include(I18n.t(state_trans))
  end

  def expect_document_upload_status
    page.all(".capybara-inquiry-card").each do |element|
      expect(element.text).to include("#{I18n.t('manager.inquiries.please_upload_document')}")
    end
  end

  def expect_document_upload_text(id)
    document_upload_key = 'manager.inquiries.please_upload_document'
    expect(find(".capybara-inquiry-card#{id}").text).to include(I18n.t(document_upload_key))
  end

end
