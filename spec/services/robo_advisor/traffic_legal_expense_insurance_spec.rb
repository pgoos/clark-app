require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Verkehrs-Rechtsschutzversicherung' do
    let!(:vrs_category) { create(:category, ident: '1bbdbb5e', name: 'Verkehrs-Rechtsschutzversicherung')}
    let!(:rs_category) { create(:category, ident: '5bfa54ce', name: 'Rechtsschutzversicherung')}

    let!(:product) { create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: vrs_category)) }

    it_behaves_like 'a robo advice for method', :traffic_legal_expense_insurance

    it 'sends the appropriate text' do
      expect do
        subject.traffic_legal_expense_insurance
      end.to change(product.interactions, :count).by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.traffic_legal_expense_insurance.recommend_more_cover'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not send an advice if the customer has another legal expense insurance' do
      create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: rs_category))

      expect do
        subject.traffic_legal_expense_insurance
      end.not_to change(product.interactions, :count)
    end
  end
end
