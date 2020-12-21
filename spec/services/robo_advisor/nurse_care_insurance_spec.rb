require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Pflegezusatz' do
    let(:company) { create(:company, ident: RoboAdvisor::GOOD_INSURERS_NURSE_CARE.sample) }
    let(:category) { create(:category, ident: RoboAdvisor::NURSE_CARE_IDENT.sample, name: 'Risikolebensversicherung') }
    let!(:product) { create(:product,
                                        mandate: mandate,
                                        plan: create(:plan, company: company, category: category),
                                        premium_period:  :year) }

    it_behaves_like 'a robo advice for method', :nurse_care_insurance

    context 'good company advice' do
      it 'send out catch all advice for products from other companies if premium > 1.00' do
        company = create(:company, ident: 'something-not-in-the-list')
        product.plan.update!(company: company)
        product.update!(premium_price: 33.0)

        expect do
          subject.nurse_care_insurance
        end.to change(product.interactions, :count).by(2)

        i18n_key = "robo_advisor.nurse_care_insurance.catch_all"
        expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
        product.reload

        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.content).not_to match(/translation missing/)
        expect(product.advices.first.content).not_to include(i18n_key)
      end

      it 'does not send out catch all advice for products from other companies if premium < 1.00' do
        company = create(:company, ident: 'something-not-in-the-list')
        product.plan.update!(company: company)
        product.update!(premium_price: 0.1)

        expect do
          subject.nurse_care_insurance
        end.not_to change(product.interactions, :count)
      end

      RoboAdvisor::GOOD_INSURERS_NURSE_CARE.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)
          product.update!(premium_price: 1.10)

          expect do
            subject.nurse_care_insurance
          end.to change(product.interactions, :count).by(2)

          i18n_key = "robo_advisor.nurse_care_insurance.good_insurers"
          expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
          product.reload

          expect(product.advices.first.content).to eq(expected_text)
          expect(product.advices.first.content).not_to match(/translation missing/)
          expect(product.advices.first.content).not_to include(i18n_key)
        end
      end
    end
  end
end
