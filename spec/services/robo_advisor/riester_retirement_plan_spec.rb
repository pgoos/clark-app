require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Riester-Rentenversicherung' do
    let(:category) { create(:category, ident: '68f0b130', name: 'Riester-Rentenversicherung') }
    let!(:product) { create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :riester_retirement_plan

    it 'sends the appropriate text for > 100€ yearly' do
      expect do
        subject.riester_retirement_plan
      end.to change { product.interactions.count }.by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.riester_retirement_plan.check_bonus'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not send an advice when product costs < 100€ yearly' do
      product.update!(premium_price: 90.0)

      expect do
        subject.riester_retirement_plan
      end.not_to change { product.interactions.count }
    end
  end
end
