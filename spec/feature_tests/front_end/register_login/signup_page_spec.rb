require 'rails_helper'
require './spec/support/features/page_objects/ember/ember_helper'
require './spec/support/features/page_objects/home_page'
require './spec/support/features/page_objects/ember/manager/contracts_cockpit_page'
require './spec/support/features/page_objects/ember/mandate-funnel/cockpit_preview_page'
require './spec/support/features/page_objects/ember/mandate-funnel/select-category/company_page'
require './spec/support/features/page_objects/ember/mandate-funnel/mandate_profiling_page'
require './spec/support/features/page_objects/ember/waiting_time_variant'

# https://clarkteam.atlassian.net/browse/JCLARK-20433
# Adding the slow tag to remove from master build
RSpec.describe "Signup Flow", :slow, :browser, type: :feature, js: true, skip: "excluded from nightly, review" do

  # Page objects
  let!(:home_page) {HomePage.new}
  let!(:cockpit_page) {CockpitPage.new}
  let!(:cockpit_preview_page) {CockpitPreviewPage.new}
  let!(:select_category_page_object) {SelectCategoryPage.new}
  let!(:select_company_page_object) {SelectCompanyPage.new}
  let!(:mandate_profile_page) {MandateProfilingPage.new}
  let!(:mandate_register_page) {MandateRegisterPage.new}
  let!(:mandate_finished_page) {MandateFinishedPage.new}
  let!(:waitingtime_variant_page) {WiatingTimeMessangingPage.new}

  context 'Sign up flows' do

    let!(:category_one) {create(:category_phv)}
    let!(:category_two) {create(:category_pkv)}
    let!(:category_gkv) {create(:category_gkv)}

    let!(:company_one) {create(:company, name: 'Jelly Fish')}
    let!(:company_two) {create(:company, name: 'Rojer rabbit')}

    context 'Lead flow' do
      let!(:lead) {create(:lead, mandate: create(:mandate))}

      before do
        login_as(lead, scope: :lead)
        cockpit_page.visit_mandate_status
        waitingtime_variant_page.set_variant_off
      end

      it 'Verify user can Register as lead with Clark web App(Lead flow)' do
        cockpit_page.expect_mandate_page

        cockpit_preview_page.click_weiter
        cockpit_preview_page.expect_cockpit_preview_page
        cockpit_preview_page.click_versicherungen_hinz

        select_category_page_object.expect_mandate_targeting_page
        select_category_page_object.select_category_id(category_gkv.id)

        select_company_page_object.expect_company_page
        select_company_page_object.click_item(company_one.id)

        select_category_page_object.expect_mandate_targeting_page
        select_category_page_object.click_submit

        mandate_profile_page.expect_mandate_profiling_page
        mandate_profile_page.fill_in_form
        mandate_profile_page.confirm_button
      end

      context 'finish registration after confirming' do
        before do
          lead.mandate = mandate_profile_page.get_confirmed_mandate(lead.mandate)
          login_as(lead, scope: :lead)
          cockpit_page.visit_mandate_status
        end

        it 'finish mandate funnel' do
          cockpit_page.click_cta
          mandate_profile_page.expect_success
          mandate_profile_page.click_cta
          mandate_register_page.expect_correct_elements
          mandate_register_page.fill_password
          mandate_register_page.click_cta
          mandate_finished_page.expect_finished_page
        end
      end

      context 'convert lead to user and proceed to cockpit' do
        before do
          user = create(:user, mandate: lead.mandate)
          login_as(user, scope: :user)
          mandate_finished_page.visit_finished
        end

        it 'proceed to cockpit' do
          mandate_finished_page.click_cta
          mandate_profile_page.expect_cockpit
        end
      end
    end


    context 'User flow' do
      let!(:lead) {create(:lead, mandate: create(:mandate))}

      context 'begin mandate process' do
        before do
          login_as(lead, scope: :lead)
          home_page.navigate_home
          waitingtime_variant_page.set_variant_off
        end

        it 'Verify user can Register with Clark App' do
          home_page.click_register_user

          cockpit_page.expect_signup_success_msg
          cockpit_page.expect_mandate_page

          cockpit_preview_page.click_weiter
          cockpit_preview_page.expect_cockpit_preview_page
          cockpit_preview_page.click_versicherungen_hinz

          select_category_page_object.expect_mandate_targeting_page
          select_category_page_object.select_category_id(category_gkv.id)

          select_company_page_object.expect_company_page
          select_company_page_object.click_item(company_one.id)

          select_category_page_object.expect_mandate_targeting_page
          select_category_page_object.click_submit

          mandate_profile_page.expect_mandate_profiling_page
          mandate_profile_page.fill_in_form
          mandate_profile_page.confirm_button
        end
      end

      context 'finish registration' do
        before do
          user = create(:user, mandate: create(:mandate))
          user.mandate = mandate_profile_page.get_confirmed_mandate(user.mandate)
          login_as(user, scope: :user)
          cockpit_page.visit_mandate_status
          waitingtime_variant_page.set_variant_off
        end

        it 'proceed to cockpit' do
          cockpit_page.click_cta
          mandate_profile_page.expect_success
          mandate_profile_page.click_cta
          mandate_profile_page.expect_cockpit
        end
      end
    end

    context 'Verify user signup error messages' do
      let!(:user) {create(:user, email: 'test@test.de', password: 'Somepassword123', mandate: create(:mandate))}

      before(:each) do
        home_page.navigate_home
        waitingtime_variant_page.set_variant_off
      end

      it 'Login with an existing user' do
        cockpit_page.register_given_user_at_homepage user.email, user.password
        cockpit_page.expect_already_registered_msg
      end

      it 'Sign up from home page' do
        cockpit_page.register_given_user_at_homepage 'new@clark.de', 'TestPassword123'
        cockpit_page.expect_signup_success_msg
        cockpit_page.expect_mandate_page
      end

      it 'Verify user cannot Signup without email and password' do
        cockpit_page.register_given_user_at_homepage '', ''
        cockpit_page.expect_email_missing_msg
        cockpit_page.expect_password_missing_msg
        cockpit_page.expect_signup_page

        # 'Verify user cannot Signup without email and password'
        cockpit_page.register_given_user_at_signup '', ''
        cockpit_page.expect_email_missing_msg
        cockpit_page.expect_password_missing_msg

        # 'Verify user cannot Signup without email'
        cockpit_page.register_given_user_at_signup '', 'Clark12345'
        cockpit_page.expect_email_missing_msg

        # 'Verify user cannot Signup without password'
        cockpit_page.register_given_user_at_signup 'test@clark.de', ''
        cockpit_page.expect_password_missing_msg

        # 'Verify user cannot Signup with Invalid Email id'
        cockpit_page.register_given_user_at_signup 'test@de', ''
        cockpit_page.expect_invalid_email_msg

        # 'Verify user cannot Signup with Invalid Password length'
        cockpit_page.register_given_user_at_signup 'test@clark.de', 'Short1'
        cockpit_page.expect_short_password_msg

        # 'Verify user cannot Signup with Invalid Password Format'
        cockpit_page.register_given_user_at_signup 'test@clark.de', 'shortpassword'
        cockpit_page.expect_invalid_password_msg
      end
    end
  end
end
