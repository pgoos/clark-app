require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Lebens- & Rentenversicherungen mit Berufsunfähigkeit' do
    let(:company) { create(:company, ident: RoboAdvisor::MORGEN_MORGEN_4_AND_5_STAR_COMPANIES.sample) }
    let(:category) { create(:category, ident: RoboAdvisor::CATEGORIES_TO_ADVICE_LIFE_RETIRMENT_WITH_BU.sample) }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, category: category, company: company)) }

    it_behaves_like 'a robo advice for method', :retirement_and_life_insurance_with_disability

    it 'does not advice product from company not in the M&M rating list' do
      product.plan.update!(company: create(:company, ident: "something-not-in-the-list"))

      expect do
        subject.retirement_and_life_insurance_with_disability
      end.not_to change { product.interactions.count }
    end

    RoboAdvisor::CATEGORIES_TO_ADVICE_LIFE_RETIRMENT_WITH_BU.each do |category_ident|
      context "Kategorie: #{category_ident}" do
       before { category.update!(ident: category_ident) }

        RoboAdvisor::MORGEN_MORGEN_4_AND_5_STAR_COMPANIES.each do |company_ident|
          it "sends M&M 4/5 star rating text for company #{company_ident}" do
            company.update!(ident: company_ident)

            subject.retirement_and_life_insurance_with_disability

            expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.retirement_and_life_insurance_with_disability.good_insurance'), product)
            expect(product.advices.first.content).to eq(expected_text)
          end
        end
      end
    end
  end
end
