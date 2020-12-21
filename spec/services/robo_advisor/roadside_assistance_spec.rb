require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'KFZ-Schutzbrief' do
    let(:category) { create(:category, ident: 'd55e03e6', name: 'KFZ-Schutzbrief') }
    let(:company) { create(:company, ident: 'adacv8ee563', name: 'ADAC') }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, category: category, company: company)) }

    it_behaves_like 'a robo advice for method', :roadside_assistance

    it 'sends the appropriate text' do
      expect do
        subject.roadside_assistance
      end.to change(product.interactions, :count).by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.roadside_assistance.every_adac_contract'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not send out an adivce for other companies' do
      other_company = create(:company)
      product.plan.update!(company: other_company)

      expect do
        subject.roadside_assistance
      end.not_to change(product.interactions, :count)
    end
  end
end
