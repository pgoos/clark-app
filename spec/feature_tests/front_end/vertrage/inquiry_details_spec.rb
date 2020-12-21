# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/manager/inquiry_details_page"

RSpec.describe "Inquiry Details", :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:details_page) { InquiryDetailsPage.new }

  # Create a user that has done all the steps
  let(:user) do
    user = create(
      :user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate)
    )

    user.mandate.info["wizard_steps"] = %w[profiling targeting confirming]
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.state = :in_creation
    user.mandate.complete!
    user
  end

  context "A standard inquiry (with ratings and tips)" do
    let!(:subcompany) { create(:subcompany) }

    let!(:category) {
      create(:category, cover_benchmark: 20, tips: ["tip one", "tip two", "tip three"])
    }

    let!(:company) {
      create(:company, logo: File.new(
        Rails.root.join("spec", "support", "assets", "avatar.jpg"),
        inquiry_blacklisted: false
      ))
    }

    let!(:inquiry) {
      create(:inquiry,
                         mandate:    user.mandate,
                         company:    company,
                         subcompany: subcompany,
                         categories: [category])
    }

    before do
      subcompany.update_attributes!(
        metadata: {"rating" => {"score" => 5, "text" => {"de" => "this is some text"}}}
      )

      DocumentType.where(id: DocumentType.customer_upload.id).update(authorized_customer_states: ["mandate_customer"])
    end

    context 'with nothing special' do
      before do
        close_browser
        disable_cookie_banner
        login_as(user, scope: :user)
        details_page.visit_page_with_category(inquiry.id, category.ident)
      end

      it "should find an uploaded document", :clark_context do
        details_page.expect_standard_elements(company, inquiry)

        details_page.open_the_upload
        attach_file("manager__inquiry__upload_button",
                    File.join(Rails.root, 'spec', 'support', 'assets', 'mandate.pdf'), :visible => false)

        details_page.expect_new_document
      end
    end

    context 'that is for a self managed product' do
      before do
        company.update_attributes!(ident: 'clarkCompany')
        login_as(user, scope: :user)
        details_page.visit_page(inquiry.id)
      end

      it 'should not show rating section' do
        details_page.expect_no_ratings
      end
    end
  end

  context "as user who is in the state accepted" do
    let(:user) do
      user = create(
        :user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate)
      )

      user.mandate.info["wizard_steps"] = %w[profiling targeting confirming]
      user.mandate.signature = create(:signature)
      user.mandate.confirmed_at = DateTime.current
      user.mandate.tos_accepted_at = DateTime.current
      user.mandate.state = :accepted
      user
    end

    let!(:company) {
      create(
        :company,
        logo: File.new(Rails.root.join("spec", "support", "assets", "avatar.jpg"),
                       inquiry_blacklisted: false)
      )
    }

    let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: company) }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(inquiry.id)
    end

    it "should show the cancel button" do
      expect(page).to have_selector(".manager__inquiry__body__abort")
    end
  end

  context "An inquiry without a company logo" do
    let!(:inquiry) {
      create(:inquiry, mandate: user.mandate, company: create(:company))
    }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(inquiry.id)
    end

    it "should show the default shield logo" do
      expect(find(".manager__inquiry__header__main__logo-container__logo")["src"])
        .to match("im-shield")
    end
  end

  context "Inquiry cancelled" do
    let(:customer_not_insured_person_cause) do
      InquiryCategory.cancellation_causes["customer_not_insured_person"]
    end

    let(:inquiry) do
      create(:inquiry,
                         mandate: user.mandate,
                         company: create(:company))
    end

    let!(:inquiry_category) do
      create(:inquiry_category,
                         state:              "cancelled",
                         inquiry:            inquiry,
                         cancellation_cause: customer_not_insured_person_cause)
    end

    let(:category) do
      inquiry_category.category.ident
    end

    before do
      login_as(user, scope: :user)
      details_page.visit_page_with_category(inquiry_category.inquiry.id, category)
    end

    it "should handle the cancelation message with a cta to invitation" do
      expected_content_tag = ".manager__inquiry__infographic-info__content"
      translation_key = "activerecord.attributes.inquiry.cancellation_cause"  \
                        ".customer_not_insured_person"

      expected_content = I18n.t(translation_key)
      find(expected_content_tag).assert_text(expected_content)

      button_class = ".manager__inquiry__header__blacklist-tips__message__ctas__cta"
      page.assert_selector(button_class)
    end
  end
end
