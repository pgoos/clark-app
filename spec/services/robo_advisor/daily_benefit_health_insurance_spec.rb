require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Krankentagegeldversicherung' do
    let(:category) { create(:category, ident: '179efb93') }

    let!(:product) { create(:product, premium_price: 33.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :daily_benefit_health_insurance

    it 'advices all products' do
      expect do
        subject.daily_benefit_health_insurance
      end.to change { product.interactions.count }

      i18n_key = 'robo_advisor.daily_benefit_health_insurance.catch_all'
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to include(i18n_key)
    end
  end
end
