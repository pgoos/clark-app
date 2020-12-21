require 'rails_helper'
require './spec/support/features/page_objects/ember/rate-us/page'

RSpec.describe 'Rate us business events within the manager section', :timeout, :clark_context, :slow, :browser, type: :feature, js: true do

  let(:locale) { I18n.locale }
  let(:page_object) { RateUsPage.new }

  # Manager pages need an instance of BU category
  let!(:bu_category) { create(:bu_category)}

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

  # All of the rate us redirects only work on the mobile device
  using_clark_app do

    context 'on cockpit' do

      context 'first time seen product' do
        let!(:product) { create(:product, mandate: user.mandate, category: bu_category) }

        before do
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        context 'rated for event already' do

          before do
            page_object.set_event("['first_product_updated']")
          end

          it 'should not go to rate us' do
            page_object.assert_rate_not_visible
          end
        end

        context 'not rated for event' do
          it 'should go to rate' do
            page_object.assert_rate_visible
          end
        end
      end

      context 'offer accepted first seen' do
        # product in the order pending state
        let!(:product) { create(:product, mandate: user.mandate, category: bu_category, state: 'order_pending') }

        before do
          login_as(user, scope: :user)
          page_object.navigate_manager
        end


        context 'rated for event already' do

          before do
            page_object.set_event("['first_product_updated', 'offer_accepted']")
          end

          it 'should not go to rate us' do
            page_object.assert_rate_not_visible
          end
        end

        context 'not rated for event' do
          it 'should go to rate' do
            page_object.assert_rate_visible
          end
        end
      end

      context 'first time seen recommendation' do
        let!(:recommendation) { create(:recommendation, mandate: user.mandate) }

        before do
          login_as(user, scope: :user)
          page_object.navigate_manager
        end

        context 'rated for event already' do
          before do
            page_object.set_event("['recommendations_available']")
          end

          it 'should not go to rate us' do
            page_object.assert_rate_not_visible
          end
        end

        context 'not rated for event' do
          it 'should go to rate', skip: "excluded from nightly, review" do
            page_object.assert_rate_visible
          end
        end
      end
    end

    context 'after leaving advice on product', skip: 'not working for now' do
      # create a product with advice
      let!(:product) { create(:product, mandate: user.mandate) }
      let!(:admin) { create(:admin) }
      let!(:message_clark) { create(:interaction_advice, topic: product, mandate: user.mandate, admin: admin, cta_link: '') }
      let!(:message_user) { create(:interaction_adivce_reply, topic: product, mandate: user.mandate) }

      before do
        login_as(user, scope: :user)
        page_object.navigate_product(product.id)
      end

      context 'rated for event already' do

        before do
          page_object.set_event("['positive_advice']")
        end

        it 'should not go to rate us' do
          find('.bot-chat__message-box__footer__rating.positive').click()
          page_object.assert_rate_not_visible
        end
      end

      context 'not rated for event' do
        it 'should go to rate' do
          find('.bot-chat__message-box__footer__rating.positive').click()
          page_object.assert_rate_visible
        end
      end
    end
  end

end
