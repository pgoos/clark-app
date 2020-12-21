require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Risikolebensversicherung' do
    let(:company) { create(:company, ident: RoboAdvisor::GOOD_INSURANCE_RISK_LIFE.sample) }
    let(:category) { create(:category, ident: 'e19db46d', name: 'Risikolebensversicherung') }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, company: company, category: category)) }

    it_behaves_like 'a robo advice for method', :risk_life_insurance

    context 'good company advice' do
      it 'send out catch all advice for products from other companies' do
        company = create(:company, ident: 'something-not-in-the-list')
        product.plan.update!(company: company)

        expect do
          subject.risk_life_insurance
        end.to change(product.interactions, :count).by(2)
      end

      RoboAdvisor::GOOD_INSURANCE_RISK_LIFE.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.risk_life_insurance
          end.to change(product.interactions, :count).by(2)

          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.risk_life_insurance.good_insurance'), product)
          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end
  end
end
