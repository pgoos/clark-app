require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Sterbegeldversicherung' do
    let(:category) { create(:category, ident: '73499856', name: 'Sterbegeldversicherung') }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :funeral_cost_insurance

    it 'sends the appropriate text' do
      expect do
        subject.funeral_cost_insurance
      end.to change(product.interactions, :count).by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.funeral_cost_insurance.every_contract'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end
  end
end
