require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Diverse Altersvorsorge Produkte (Company Rules with M&M Rating)' do
    let(:company) { create(:company, ident: RoboAdvisor::MORGEN_MORGEN_4_AND_5_STAR_COMPANIES.first) }
    let(:category) { create(:category, ident: RoboAdvisor::CATEGORIES_TO_ADVICE_RETIREMENT_PRODUCTS.first) }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, category: category, company: company)) }

    it_behaves_like 'a robo advice for method', :retirement_contracts

    it 'does not advice product from company not in the M&M rating list' do
      company = create(:company, ident: 'something-not-in-the-list')
      category = create(:category, ident: 'something-else-not-in-the-list')
      product.plan.update!(company: company)
      product.plan.update!(category: category)

      expect do
        subject.retirement_contracts
      end.not_to(change { product.interactions.count })
    end

    it "sends catch all for Kapitallebens category" do
      company.update!(ident: "not-in-morgen-morgen")
      category.update!(ident: RoboAdvisor::CAPITAL_LIFE_INSURANCE)

      subject.retirement_contracts

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.capital_life_insurance.catch_all'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    RoboAdvisor::CATEGORIES_TO_ADVICE_RETIREMENT_PRODUCTS[0,1].each do |category_ident|
      context "Kategorie: #{category_ident}" do
       before { category.update!(ident: category_ident) }

        RoboAdvisor::MORGEN_MORGEN_4_AND_5_STAR_COMPANIES[0,1].each do |company_ident|
          it "sends M&M 4/5 star rating text for company #{company_ident}" do
            company.update!(ident: company_ident)

            subject.retirement_contracts

            expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.retirement_contracts.mm_4_and_5_star'), product)
            expect(product.advices.first.content).to eq(expected_text)
          end
        end

        RoboAdvisor::MORGEN_MORGEN_3_STAR_COMPANIES[0,1].each do |company_ident|
          it "sends M&M 3 star rating text for company #{company_ident}" do
            company.update!(ident: company_ident)

            subject.retirement_contracts

            expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.retirement_contracts.mm_3_star'), product)
            expect(product.advices.first.content).to eq(expected_text)
          end
        end

        RoboAdvisor::MORGEN_MORGEN_2_AND_1_STAR_COMPANIES[0,1].each do |company_ident|
          it "sends M&M 2/1 star rating text for company #{company_ident} (contract started after 01.01.2011)" do
            company.update!(ident: company_ident)
            product.update!(contract_started_at: DateTime.new(2011, 1, 1, 12, 0))

            subject.retirement_contracts

            expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.retirement_contracts.mm_2_and_1_star_after_2011'), product)
            product.reload

            expect(product.advices.first.content).to eq(expected_text)
          end
        end

        RoboAdvisor::MORGEN_MORGEN_2_AND_1_STAR_COMPANIES[0,1].each do |company_ident|
          it "sends M&M 2/1 star rating text for company #{company_ident} (contract started before 01.01.2011)" do
            company.update!(ident: company_ident)
            product.update!(contract_started_at: DateTime.new(2010, 12, 31, 12, 0))

            subject.retirement_contracts

            expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.retirement_contracts.mm_2_and_1_star_before_2011'), product)
            product.reload

            expect(product.advices.first.content).to eq(expected_text)
          end
        end
      end
    end
  end
end
