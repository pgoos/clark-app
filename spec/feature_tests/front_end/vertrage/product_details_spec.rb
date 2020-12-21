require 'rails_helper'
require './spec/support/features/page_objects/ember/manager/product_details_page'

RSpec.describe "Product Details", :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:details_page) { ProductDetailsPage.new }

  # Create a user that has done all the steps
  let(:user) do
    user = create(:user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate))
    user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
    user.mandate.signature = create(:signature)
    # Need gender for automated gkv
    user.mandate.gender = 'male'
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.state = :in_creation
    user.mandate.complete!
    user
  end

  context 'with a standard product' do
    let(:subcompany) { create(:subcompany) }
    let(:company) { create(:company) }
    let(:category) { create(:category, cover_benchmark: 20, tips: ['tip one', 'tip two', 'tip three']) }
    let(:plan) { create(:plan, company: company, category: category, subcompany: subcompany) }
    let(:product) { create(:product, :with_sales_fee, mandate: user.mandate, plan: plan, contract_ended_at: DateTime.new(2010, 1, 2, 0, 0, 0)) }

    before do
      subcompany.update_attributes!(metadata: {'rating' => {'score' => 5, 'text' => {'de' => 'this is some text'}}})
    end

    context 'with nothing special' do

      before do
        close_browser
        login_as(user, scope: :user)
        details_page.visit_page(product.id)
      end

      it "show correct page elements", :clark_context do
        details_page.expect_standard_elements(product)
        details_page.expect_contract_end_in_details
        # details_page.expect_sales_fee_in_details # TODO: check if it's still actual.
      end

    end

    context 'that is for a self managed product' do

      before do
        company.update_attributes!(ident: 'clarkCompany')
        login_as(user, scope: :user)
        details_page.visit_page(product.id)
      end

      it 'should not show rating section' do
        details_page.expect_no_ratings
      end

    end

  end

  context 'in state ordered or pending' do
    let(:product) { create(:product, mandate: user.mandate, state: 'order_pending') }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(product.id)
    end

    it 'shows the ordered state on the product' do
      details_page.premium_shows_correct_value(I18n.t("manager.products.show.ordered"))
    end
  end

  context 'with a contract that will expire' do
    let(:category) { create(:category, ident: '1111', termination_period: 3) }
    let(:product) {
      create(:product,
      mandate: user.mandate,
      category: category,
      contract_ended_at: DateTime.current.advance(years: 1),
      state: 'under_management'
      ) }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(product.id)
    end

    it 'should say that the contract is going to expire in x time' do
      details_page.expect_duration_data
    end
  end

  context 'with a contract that will expire, but for a disallowed ident' do
    let(:category) { create(:category, ident: '350e7cf9', termination_period: 3) }
    let(:product) { create(
      :product,
      mandate: user.mandate,
      contract_ended_at: DateTime.current.advance(years: 1),
      state: 'under_management',
      category: category)
    }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(product.id)
    end

    it 'should not show the experation period' do
      details_page.expect_no_duration_data
    end

  end

  context 'premium on hold' do
    let(:product) do
      product = create(
          :product,
          mandate: user.mandate,
          premium_price: '00,00',
          premium_state: 'on_hold'
      )
      product
    end

    before do
      login_as(user, scope: :user)
      details_page.visit_page(product.id)
    end

    it 'shows the on hold state on the product' do
      details_page.premium_shows_correct_value(I18n.t("manager.products.show.no_premium"))
    end
  end

  context 'when the product has a linked quesitonnaire' do
    let(:admin_questionnaire) { create(:admin) }
    let(:company) { create(:company) }
    let(:category_questionnaire) { create(:questionnaire) }
    let(:questionnaire_response) {
      create(:questionnaire_response,
                        mandate: user.mandate,
                        questionnaire: category_questionnaire,
                        state: "completed",
                        created_at: 1.year.ago)
    }
    let(:category) { create(:category, questionnaire: category_questionnaire) }
    let(:category_questionnaire_plan) { create(:plan, category: category, company: company) }
    let(:sample_interaction) { create(:interaction_advice, topic: product_with_questionnaire, mandate: user.mandate, admin: admin_questionnaire, cta_link: '') }
    let(:opportunity) { create(
      :opportunity,
      source: questionnaire_response,
      category_id: category.id,
      mandate: user.mandate,
      state: 'created'
    )}
    let(:product_with_questionnaire) { create(
      :product,
      opportunities: [opportunity],
      plan: category_questionnaire_plan,
      mandate: user.mandate)
    }
    before do
      login_as(user, scope: :user)
      details_page.visit_page(product_with_questionnaire.id)
    end

    it 'should show the questionnaire button as we have a linked questionnaire' do
      details_page.expect_linked_questionnaire(category_questionnaire)
    end

    context 'and the user has filled the questioannire in' do
      it 'should show the "you have completed the questionnaire section"' do
        details_page.expect_questioannire_will_be_analized
        details_page.expect_linked_questionnaire(category_questionnaire)
      end
    end

  end

  context 'with a standard message' do
    let(:product_message) { create(:product, mandate: user.mandate) }
    let(:admin_message) { create(:admin) }
    let(:message_clark) { create(:interaction_advice, topic: product_message, mandate: user.mandate, admin: admin_message, cta_link: '') }
    let(:message_user) { create(:interaction_adivce_reply, topic: product_message, mandate: user.mandate) }

    before do
      message_clark.update_attributes(metadata: {'sent' => 1, 'helpful' => nil})
      login_as(user, scope: :user)
      details_page.visit_page(product_message.id)
    end

    it 'should show the correct elements' do
      details_page.advice_has_content("Something the admin says about the contract")
      details_page.expect_standard_message_elements
    end

    it 'should allow us to submit was helpful' do
      details_page.expect_helpful_buttons
      details_page.click_was_helpful
      details_page.expect_helpful_thanks_message
    end

    it 'should allow us to submit not helpful' do
      details_page.expect_helpful_buttons
      details_page.click_was_not_helpful
      details_page.expect_helpful_thanks_message
    end

  end


  context 'with an offer' do
    let(:admin_offer) { create(:admin) }
    let(:offer) { create(:active_offer_with_old_tarif, mandate: user.mandate) }
    let(:opportunity) { create(:opportunity, state: 'offer_phase', offer: offer, mandate: user.mandate, old_product: offer.old_product) }
    let(:advice) { create(:interaction_advice, topic: offer.old_product, mandate: user.mandate, admin: admin_offer, cta_link: '') }

    before do
      offer
      opportunity
      advice
      admin_offer
      offer.old_product.update(mandate: user.mandate)
      login_as(user, scope: :user)
      details_page.visit_page(offer.old_product.id)
    end

    it 'should show correct page elements' do
      details_page.expect_offer_ready_text(offer, offer.old_product)
      details_page.navigate_click(".manager__product__details__message__ctas__cta--offer", "offers/#{offer.id}")
    end
  end

  context 'with an offer advice' do
    let(:product_advice) { create(:product, mandate: user.mandate) }
    let(:opportunity) { create(:opportunity, state: 'offer_phase', offer: nil, mandate: user.mandate, old_product: product_advice) }

    before do
      product_advice
      opportunity
      login_as(user, scope: :user)
      details_page.visit_page(product_advice.id)
    end

    it 'should not navigate to anywhere when clicking the offer button' do
      details_page.navigate_click('.manager__product__details__message__ctas__cta--offer-notification', "manager/products/#{product_advice.id}")
    end

  end

  context 'a product with commission details' do
    let(:product_commision) {
      create(
          :product,
          mandate: user.mandate,
          portfolio_commission_price: 20.20,
          portfolio_commission_period: 'year'
      )
    }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(product_commision.id)
    end

    # comment out this section, because we disabled showing commissions, see
    # - https://clarkteam.atlassian.net/browse/JCLARK-47020
    # - https://clarkteam.atlassian.net/browse/JCLARK-49739

    # it 'should show the commissions in the details section of the products' do
    #   details_page.expect_commissions
    # end

  end

  context 'a product with coverage features' do

    # Add the features to the catgeory
    let!(:category) { create(:category, coverage_features: [
        FactoryBot.build(:coverage_feature, name: 'Feature one', identifier: 'feature-1'),
        FactoryBot.build(:coverage_feature, name: 'Feature two', identifier: 'feature-2', value_type: 'Boolean'),
        FactoryBot.build(:coverage_feature, name: 'Feature three', identifier: 'feature-3', value_type: 'Boolean')
    ]) }

    let(:company) { create(:company) }
    let(:plan) { create(:plan, company: company, category: category) }

    # Then add them to the product
    let(:product) { create(
        :product,
        mandate: user.mandate,
        plan: plan,
        coverages: {
            'feature-1' => ValueTypes::Money.new(5_000_000, 'EUR'),
            'feature-2' => ValueTypes::Boolean::TRUE,
            'feature-3' => ValueTypes::Boolean::FALSE
        }
    ) }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(product.id)
    end

    it 'should show correct page elements' do
      details_page.expect_coverage_features
    end
  end

  context 'a product with documents' do
    let(:policy_document) { create(:document, document_type: DocumentType.policy) }
    # This doc should not be shown
    let(:offer_replace_document) { create(:document, document_type: DocumentType.offer_replace) }
    let(:invoice_document) { create(:document, document_type: DocumentType.invoice) }
    let(:product) { create(:product, mandate: user.mandate, documents: [
        policy_document,
        offer_replace_document,
        invoice_document
    ]) }

    before do
      user.mandate.accept!
      login_as(user, scope: :user)
      details_page.visit_page(product.id)
    end

    it 'show correct page elements' do
      details_page.expect_documents(2)
    end
  end

  context 'a product with an automated gkv message' do
    before do
      Inquiry.skip_callback(:create, :after, :accept_inquiry, raise: false)
    end

    let(:sample_coverage_feature_id) { 'boolean_247srvctlfn_4d2186' }

    let!(:advice_admin) { create(:advice_admin) }

    let(:tk_subcompany) { create(:subcompany_gkv, name: 'Techniker Krankenkasse', ident: 'technfac6e4') }
    let!(:tk_plan) { create(:plan, subcompany: tk_subcompany, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE}) }

    let(:hkk_subcompany) { create(:subcompany_gkv, name: 'Handelskrankenkasse (hkk)', ident: 'handec9db4e') }
    let!(:hkk_plan) { create(:plan, subcompany: hkk_subcompany, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE}) }

    let!(:gkv_company) { create(:gkv_company, gkv_whitelisted: true, national_health_insurance_premium_percentage: 1.5) }
    let!(:inquiry) { create(:inquiry, company: gkv_company, mandate: user.mandate) }

    let!(:gkv_plan) { create(:plan_gkv, coverages: {sample_coverage_feature_id => ValueTypes::Boolean::TRUE}, company: gkv_company) }
    let!(:product) { create(:product, mandate: user.mandate, inquiry: inquiry, plan: gkv_plan, created_at: 2.hours.ago) }

    let!(:offer) do
      Sales::Advices::GkvAdviceFactory.create_advice_premium_bucket1!(product)
      automation_rule = Sales::Rules::OptimizeGkvRuleTkHkk.new(inquiry: inquiry, mandate: user.mandate, old_product: product)
      Sales::GkvOfferService.new.apply_offer_automation_rule(automation_rule, product)
      offer = Offer.last
      offer.send_offer
      offer
    end

    context 'offer exists' do

      before(:each) do
        login_as(user, scope: :user)
        details_page.visit_page(product.id)
      end

      it 'should show the correct page elements' do
        details_page.expect_offer_button
        sleep 3
        details_page.navigate_click(".manager__product__details__message__ctas__cta--offer", "offers/#{offer.id}")
      end
    end

    context 'oppportunity has been lost' do

      before(:each) do
        product.opportunities.first.update_attributes!(state: 'lost')
        login_as(user, scope: :user)
        details_page.visit_page(product.id)
      end

      it 'should not show the GKV offer button' do
        details_page.expect_no_offer_button
      end
    end

  end

end
