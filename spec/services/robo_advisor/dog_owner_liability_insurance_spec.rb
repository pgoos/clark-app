require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Hundehaftpflicht' do
    let(:category) { create(:category, ident: 'd2583b1a', name: 'Hundehaftpflicht') }
    let!(:product) { create(:product, premium_price: 60.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :dog_owner_liability_insurance

    it 'sends the appropriate text for < 70€ yearly' do
      expect do
        subject.dog_owner_liability_insurance
      end.to change { product.interactions.count }.by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.dog_owner_liability_insurance.ok'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not send an advice when product costs over 70€ yearly' do
      product.update!(premium_price: 80.0)

      expect do
        subject.dog_owner_liability_insurance
      end.not_to change { product.interactions.count }
    end
  end
end
