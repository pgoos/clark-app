require 'rails_helper'
require './spec/support/features/page_objects/ember/mandate-funnel/mandate_register_page'
require './spec/support/features/page_objects/ember/mandate-funnel/cockpit_preview_page'

RSpec.describe "Ember Mandate register page", :browser, type: :feature, js: true, skip: true do
  let(:locale) { I18n.locale }

  let!(:lead) do
    user = create(:lead, mandate: create(:mandate))
    user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.state = :in_creation
    user
  end

  let(:page_object) { MandateRegisterPage.new }


  # FYI This is iOS only
  using_clark_app do
    context 'logged in' do
      before(:each) do
        login_as(lead, scope: :lead)
        page_object.visit_page(false)
      end

      it 'shows the correct elements' do
        page_object.expect_correct_elements
        page_object.expect_push(false)
      end

      context 'with push notifications not set' do

        it 'should have push notification not toggled' do
          page_object.expect_push(true)
          page_object.expect_toggle_off
        end

        it 'should show the message about disabling in settings on click of toggle after already toggled' do
          page_object.click_toggle
          page_object.expect_toggle_on
          page_object.expect_settings_message(false)
          page_object.click_toggle
          page_object.expect_settings_message(true)
        end
      end

    end

    context 'with push notification set as true' do
      before(:each) do
        login_as(lead, scope: :lead)
        page_object.visit_page(true)
      end

      it 'should not show the entire section' do
        page_object.expect_push(false)
      end
    end
  end
end
