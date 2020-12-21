require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Reisegepäckversicherung' do
    let(:category) { create(:category, ident: 'b35689d5', name: 'Reisegepäckversicherung') }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :luggage_insurance

    it 'sends the appropriate text' do
      subject.luggage_insurance

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.luggage_insurance.every_contract'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end
  end
end
