require 'rails_helper'
require './spec/support/features/page_objects/ember/rate-us/page'

RSpec.describe 'Rate us logic for deciding if to show the rate us modal', :timeout, :clark_context, :browser, type: :feature, js: true do

  let(:locale) { I18n.locale }
  let(:page_object) { RateUsPage.new }
  let!(:bu_category) { create(:bu_category) }
  let(:modal_helper) { ManagerAcceptedOfferModal.new }

  using_clark_app do

    context 'as a lead' do
      let!(:lead) { create(:device_lead, mandate: create(:mandate)) }
      let!(:product) { create(:product, mandate: lead.mandate, category: bu_category) }

      before do
        login_as(lead, scope: :lead)
        page_object.navigate_manager
      end

      it 'does not navigate to rate' do
        page_object.assert_rate_not_visible
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end

    context 'as unconfirmed user' do
      let!(:user_unconfirmed) { create(:user, mandate: create(:mandate), confirmed_at: nil) }
      let!(:product) { create(:product, mandate: user_unconfirmed.mandate, category: bu_category) }

      before do
        login_as(user_unconfirmed, scope: :user)
        page_object.navigate_manager
      end

      it 'does not navigate to rate' do
        page_object.assert_rate_not_visible
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end

    context 'as a user who is a critic' do

      let!(:critic_user) do
        user = create(:user, mandate: create(:mandate))
        user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
        user.mandate.signature = create(:signature)
        user.mandate.confirmed_at = DateTime.current
        user.mandate.tos_accepted_at = DateTime.current
        user.mandate.state = :in_creation
        # Set the user as a critic
        user.mandate.variety = :critic
        user.mandate.complete!
        user
      end

      let!(:product) { create(:product, mandate: critic_user.mandate, category: bu_category) }

      before do
        login_as(critic_user, scope: :user)
        page_object.navigate_manager
      end

      it 'does not navigate to rate' do
        page_object.assert_rate_not_visible
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end
  end

  context 'with confirmed user not critic' do
    let!(:user) do
      mandate = create(:mandate)
      user = create(:user, confirmation_sent_at: 2.days.ago, mandate: mandate)
      user.mandate.info["wizard_steps"] = %w[profiling targeting confirming]
      user.mandate.signature = create(:signature)
      user.mandate.confirmed_at = DateTime.current
      user.mandate.tos_accepted_at = DateTime.current
      user.mandate.state = :accepted
      user.mandate.save!
      user
    end
    let!(:product) { create(:product, mandate: user.mandate, category: bu_category) }

    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
    end

    context 'and accept the offer on the website' do
      context 'not previously rated' do
        before do
          user.mandate.info["just_accepted_offer"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context 'previously rated' do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 1
          user.mandate.info["rating_modal_shown_timestamp"] = DateTime.current
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end
    end

    using_android_app do
      context 'not previously rated' do
        before do
          user.mandate.info["just_accepted_offer"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context 'previously rated' do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 1
          user.mandate.info["rating_modal_shown_timestamp"] = DateTime.current
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end
    end

    context 'and invite them friends on the website' do
      context 'not previously rated' do
        before do
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context 'previously rated' do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 1
          user.mandate.info["rating_modal_shown_timestamp"] = DateTime.current
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end
    end

    using_android_app do
      context 'not previously rated' do
        before do
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context 'previously rated' do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 1
          user.mandate.info["rating_modal_shown_timestamp"] = DateTime.current
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end
    end

    context 'and 1 year passed then login on the website' do
      before do
        user.mandate.info["cta_bewerten"] = true
        user.mandate.info["cta_bewerten_timestamp"] = 365.days.ago
        login_as(user, scope: :user)
        page_object.navigate_manager
      end

      it 'user should see rate us modal popup' do
        page_object.assert_rate_visible
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end

    using_android_app do
      context "previously rated " do
        before do
          user.mandate.info["cta_bewerten"] = true
          user.mandate.info["cta_bewerten_timestamp"] = 365.days.ago
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should see rate us modal popup' do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end
    end

    context 'and less than 1 year passed then login on the website' do
      before do
        user.mandate.info["cta_bewerten"] = true
        user.mandate.info["cta_bewerten_timestamp"] = 200.days.ago
        login_as(user, scope: :user)
        page_object.navigate_manager
      end

      it 'user should not see rate us modal popup' do
        page_object.assert_rate_not_visible
      end

      after do
        modal_helper.reset_localStorage_rating_settings
      end
    end

    using_android_app do
      context "previously rated" do
        before do
          user.mandate.info["cta_bewerten"] = true
          user.mandate.info["cta_bewerten_timestamp"] = 200.days.ago
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it 'user should not see rate us modal popup' do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end
    end

    context "reminder cycle of rating modal" do

      context "triggered after seen rating modal within 30 days" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 1
          user.mandate.info["rating_modal_shown_timestamp"] = 19.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should not show rate us modal popup" do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context "saw more than 30 days ago" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 1
          user.mandate.info["rating_modal_shown_timestamp"] = 39.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should show rate us modal popup" do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context "saw after 30 days but before 60 days" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 2
          user.mandate.info["rating_modal_shown_timestamp"] = 39.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should not show rate us modal popup" do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context "saw more than 60 days ago" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 2
          user.mandate.info["rating_modal_shown_timestamp"] = 65.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should show rate us modal popup" do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context "closed after 60 days but before 180 days" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 2
          user.mandate.info["rating_modal_shown_timestamp"] = 65.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should not show rate us modal popup" do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context "closed more than 180 days ago" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 2
          user.mandate.info["rating_modal_shown_timestamp"] = 185.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should show rate us modal popup" do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end
      end

      context "closed after 180 days but before 360 days" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 2
          user.mandate.info["rating_modal_shown_timestamp"] = 185.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should not show rate us modal popup" do
          page_object.assert_rate_not_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end

      end

      context "closed more than 360 days ago" do
        before do
          user.mandate.info["rating_modal_shown_frequency"] = 2
          user.mandate.info["rating_modal_shown_timestamp"] = 365.days.ago
          user.mandate.info["link_shares"] = true
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        it "should show rate us modal popup" do
          page_object.assert_rate_visible
        end

        after do
          modal_helper.reset_localStorage_rating_settings
        end

      end
    end

  end
end
