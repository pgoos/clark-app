require 'rails_helper'
require './spec/support/features/page_objects/ember/enable-push/page'

RSpec.describe 'Push notification modal aka the enable push route', :timeout, :slow, :clark_context, :browser, type: :feature, js: true do

  let(:locale) { I18n.locale }
  let(:page_object) { EnablePushPage.new }

  # for manager pages cockpit API request
  let!(:bu_category) { create(:bu_category) }

  let!(:user) do
    user = create(:user, mandate: create(:mandate))
    user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.state = :in_creation
    user.mandate.complete!
    user
  end

  context 'with correct conditions' do
    let!(:questionnaire) { create(:questionnaire) }
    let!(:questionnaire_response) { create(:questionnaire_response, questionnaire: questionnaire, state: 'completed', created_at: 2.days.ago, mandate: user.mandate)}
    let!(:category) { create(:category, questionnaire: questionnaire) }
    let!(:recommendation) { create(:recommendation, mandate: user.mandate, category: category) }

    before do
      login_as(user, scope: :user)
      page_object.navigate_manager
    end

    context 'on the web' do
      # Even if we fake the correct state
      it 'should not go to modal' do
        page_object.assert_not_navigated_to_enable_push
      end
    end

    using_android_app do
      # Should not show on android (push enabled by default)
      it 'should not go to modal' do
        page_object.assert_not_navigated_to_enable_push
      end
    end

  end

  using_clark_app do

    context 'not done questionaire' do

      before do
        login_as(user, scope: :user)
        page_object.navigate_manager
      end

      it 'should not go to modal' do
        page_object.assert_not_navigated_to_enable_push
      end

    end

    context 'done a questionaire' do
      let!(:questionnaire) { create(:questionnaire) }
      let!(:questionnaire_response) { create(:questionnaire_response, questionnaire: questionnaire, state: 'completed', created_at: 2.days.ago, mandate: user.mandate)}
      let!(:category) { create(:category, questionnaire: questionnaire) }
      let!(:recommendation) { create(:recommendation, mandate: user.mandate, category: category) }

      context 'push enabled' do

        before do
          login_as(user, scope: :user)
          page_object.navigate_manager
          page_object.set_push_enabled("true")
        end

        it 'should not go to modal' do
          page_object.assert_not_navigated_to_enable_push
        end
      end

      context 'push not enabled' do
        context 'seen already' do

          before do
            login_as(user, scope: :user)
            page_object.navigate_manager
            page_object.set_event("request_push_access")
          end

          it 'should not go to modal' do
            page_object.assert_not_navigated_to_enable_push
          end
        end

        context 'not seen before' do

          before do
            login_as(user, scope: :user)
            page_object.navigate_manager
          end

          it 'should show correct elements', skip: "excluded from nightly, review" do
            page_object.assert_correct_username(user.mandate)
            page_object.assert_icon_visible
            page_object.assert_has_cta
            page_object.assert_correct_copy
          end

          # Cannot test out of scope interactions like actually rating
        end
      end

    end

  end
end
