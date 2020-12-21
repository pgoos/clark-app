require 'rails_helper'
require './spec/support/features/page_objects/ember/waiting_time_variant'
require './spec/support/features/page_objects/ember/manager/inquiry_details_page'
require './spec/support/features/page_objects/ember/manager/inquiry_list_page'
require './spec/support/features/page_objects/ember/manager/contracts_cockpit_page'

RSpec.describe "Tests for the variant of waiting time messenging", :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:pageobject) { WiatingTimeMessangingPage.new }
  let(:inquiry_details_po) { InquiryDetailsPage.new }
  let(:inquiry_list_po) { InquiryListPage.new }
  let(:cockpit_po) { ContractsPage.new }

  context 'inquiry details page' do

    let(:user) do
      user = create(:user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate))
      user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
      user.mandate.signature = create(:signature)
      user.mandate.confirmed_at = DateTime.current
      user.mandate.tos_accepted_at = DateTime.current
      user.mandate.state = :in_creation
      user.mandate.complete!
      user
    end

    context 'on variant' do
      context 'with waiting time not accepted' do

        context 'blacklist' do
          let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: create(:company, inquiry_blacklisted: true))}

          before(:each) do
            login_as(user, scope: :user)
            inquiry_details_po.visit_page(inquiry.id)
            pageobject.reset_decided_on_inq_waiting
          end

          it 'shows correct page elements' do
            inquiry_details_po.expect_variant_title
            inquiry_details_po.expect_no_expert_details
            inquiry_details_po.expect_lovely_infographic
            inquiry_details_po.expect_no_whitelist_truck
            inquiry_details_po.expect_no_accept_clark_waiting_time_link
            inquiry_details_po.expect_cancel_inq_link
          end
        end

        context 'whitelist' do
          let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: create(:company, inquiry_blacklisted: false))}

          before(:each) do
            login_as(user, scope: :user)
            inquiry_details_po.visit_page(inquiry.id)
            pageobject.reset_decided_on_inq_waiting
          end

          it 'shows correct elements and reverts when accepting waiting time' do
            inquiry_details_po.expect_variant_title
            inquiry_details_po.expect_no_waiting_time
            inquiry_details_po.expect_no_waiting_time_descr
            inquiry_details_po.expect_lovely_infographic
            inquiry_details_po.expect_whitelist_truck
            inquiry_details_po.expect_accept_clark_waiting_time_link
            inquiry_details_po.expect_cancel_inq_link

            inquiry_details_po.click_accept_waiting_time
            sleep 1

            inquiry_details_po.expect_no_variant_title
            inquiry_details_po.expect_waiting_time
            inquiry_details_po.expect_no_lovely_infographic
            inquiry_details_po.expect_no_whitelist_truck
            inquiry_details_po.expect_no_accept_clark_waiting_time_link
            inquiry_details_po.expect_cancel_inq_link

          end

        end
      end

      context 'waiting time accepted' do

        context 'blacklist' do
          let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: create(:company, inquiry_blacklisted: true))}

          before(:each) do
            login_as(user, scope: :user)
            inquiry_details_po.visit_page(inquiry.id)
            pageobject.set_decided_on_inq_waiting
          end

          it 'shows correct page elements' do
            inquiry_details_po.expect_variant_title
            inquiry_details_po.expect_no_waiting_time
            inquiry_details_po.expect_no_expert_details
            inquiry_details_po.expect_lovely_infographic
            inquiry_details_po.expect_cancel_inq_link
          end
        end

        context 'whitelist' do
          let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: create(:company, inquiry_blacklisted: false))}

          before(:each) do
            login_as(user, scope: :user)
            inquiry_details_po.visit_page(inquiry.id)
            pageobject.set_decided_on_inq_waiting
          end

          it 'shows correct page elements' do
            inquiry_details_po.expect_no_variant_title
            inquiry_details_po.expect_waiting_time
            inquiry_details_po.expect_pickup_service_active_text
            inquiry_details_po.expect_no_lovely_infographic
            inquiry_details_po.expect_no_whitelist_truck
            inquiry_details_po.expect_no_accept_clark_waiting_time_link
            inquiry_details_po.expect_cancel_inq_link
          end
        end

      end

      context 'with documents uploaded' do
        let!(:document) { create(:document, document_type: DocumentType.customer_upload) }
        let!(:inquiry_category) { create(:inquiry_category, documents: [document]) }
        let!(:inquiry) { create(:inquiry, mandate: user.mandate, inquiry_categories: [inquiry_category])}

        context 'blacklist' do
          before(:each) do
            inquiry.company.inquiry_blacklisted = true
            inquiry.save!
            login_as(user, scope: :user)
            inquiry_details_po.visit_page_with_category(inquiry.id, inquiry_category.category.ident)
          end

          it 'shows the correct page elements' do
            inquiry_details_po.expect_two_three_days_title
            inquiry_details_po.expect_document_uploaded_text
            inquiry_details_po.expect_no_lovely_infographic
            inquiry_details_po.expect_cancel_inq_link
          end
        end

        context 'whitelist' do
          before(:each) do
            inquiry.company.inquiry_blacklisted = false
            inquiry.save!
            login_as(user, scope: :user)
            inquiry_details_po.visit_page_with_category(inquiry.id, inquiry_category.category.ident)
          end

          it 'shows the correct page elements' do
            inquiry_details_po.expect_two_three_days_title
            inquiry_details_po.expect_no_lovely_infographic
            inquiry_details_po.expect_document_uploaded_text
            inquiry_details_po.expect_cancel_inq_link
          end
        end
      end
    end
  end

  context 'inquiries list card styles' do
    let(:user) do
      user = create(:user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate))
      user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
      user.mandate.signature = create(:signature)
      user.mandate.confirmed_at = DateTime.current
      user.mandate.tos_accepted_at = DateTime.current
      user.mandate.state = :in_creation
      user.mandate.complete!
      user
    end

    context "on varaint" do
      context "with documents" do
        let!(:category1) { create(:category_phv) }
        let!(:category2) { create(:category_legal) }
        let!(:document_bl) { create(:document, document_type: DocumentType.customer_upload) }
        let!(:document_wl) { create(:document, document_type: DocumentType.customer_upload) }
        let!(:inquiry_category_bl) { create(:inquiry_category, documents: [document_bl], category: category1) }
        let!(:inquiry_category_wl) { create(:inquiry_category, documents: [document_wl], category: category2) }
        let!(:inquiry_blacklist) { create(:inquiry, mandate: user.mandate, inquiry_categories: [inquiry_category_bl], company: create(:company, inquiry_blacklisted: true))}
        let!(:inquiry_whitelist) { create(:inquiry, mandate: user.mandate, inquiry_categories: [inquiry_category_wl], company: create(:company, inquiry_blacklisted: false))}

        before do
          login_as(user, scope: :user)
          cockpit_po.visit_page
          pageobject.reset_decided_on_inq_waiting
        end

        it "should not show any arrows for any type of inquiry" do
          inquiry_list_po.expect_to_have_count_of_inquiry_cards(2)
        end
      end

      context 'accepted waiting time' do
        let!(:inq_cat) { create(:inquiry_category) }

        context 'whitelist' do
          let!(:inquiry) { create(:inquiry, mandate: user.mandate, inquiry_categories: [inq_cat], company: create(:company, inquiry_blacklisted: false))}

          before(:each) do
            login_as(user, scope: :user)
            cockpit_po.visit_page
            pageobject.set_decided_on_inq_waiting
          end

          it 'should show pickup service active text' do
            inquiry_list_po.expect_pickup_service_active_text
          end
        end
      end

      context 'not accepted waiting time' do
        let!(:inq_cat) { create(:inquiry_category) }
        let!(:inq_cat_two) { create(:inquiry_category) }
        let!(:inquiry_blacklist) { create(:inquiry, mandate: user.mandate, inquiry_categories: [inq_cat], company: create(:company, inquiry_blacklisted: true))}
        let!(:inquiry_whitelist) { create(:inquiry, mandate: user.mandate, inquiry_categories: [inq_cat_two], company: create(:company, inquiry_blacklisted: false))}

        before(:each) do
          login_as(user, scope: :user)
          cockpit_po.visit_page
          pageobject.reset_decided_on_inq_waiting
        end

        it 'should show Bitte Dokument hochladen on both inquiries' do
          inquiry_list_po.expect_document_upload_status
        end
      end
    end
  end
end
