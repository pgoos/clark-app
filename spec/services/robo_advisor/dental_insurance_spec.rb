require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Zahnzusatzversicherung' do
    let(:category) { create(:category, ident: '377e1f7c', name: 'Zahnzusatzversicherung pf') }
    let!(:product) { create(:product, premium_price: 370.0, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :dental_insurance

    it 'sends the appropriate text for < 400€ yearly' do
      expect do
        subject.dental_insurance
      end.to change { product.interactions.count }.by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.dental_insurance.ok'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not send an advice when product costs over 400€ yearly' do
      product.update!(premium_price: 400.0)

      expect do
        subject.dental_insurance
      end.not_to change { product.interactions.count }
    end

    context 'good company (with payment) advice' do
      let(:company) { create(:company) }
      before { product.update!(premium_price: 450.0, company: company) }

      RoboAdvisor::IMPROVE_DENTAL_INSURANCE.each do |company_ident|
        it "sends out improve insurance for company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.dental_insurance
          end.to change(product.interactions, :count).by(2)

          advice_text_ident = 'robo_advisor.dental_insurance.improve'
          expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
          product.reload
          expect(product.advices.first.content).not_to include(advice_text_ident)
          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end
  end
end
