require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  RSpec.shared_examples 'pkv tests' do
    context 'contract_started_at' do
      it 'advices product when contract started more than 5 years ago' do
        product.update!(contract_started_at: 5.years.ago - 1.day)

        expect do
          subject.private_health_insurance
        end.to change { product.interactions.count }.by(2)
          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.private_health_insurance.five_year_contract'), product)
          product.reload

          expect(product.advices.first.content).to eq(expected_text)
      end

      it 'advices product using the catch all if contract started less than 5 years ago' do
        product.update!(contract_started_at: 5.years.ago + 1.day)

        expect do
          subject.private_health_insurance
        end.to change { product.interactions.count }.by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.private_health_insurance.catch_rest'), product)
        product.reload

        expect(product.advices.first.content).to eq(expected_text)
      end
    end

    context 'good company advice' do
      before { product.update!(contract_started_at: 1.day.ago) }

      RoboAdvisor::GOOD_INSURANCE_PRIVATE_HEALTH.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.private_health_insurance
          end.to change(product.interactions, :count).by(2)

          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.private_health_insurance.good_insurance'), product)
          product.reload

          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end
  end

  context 'Private Krankenversicherung' do
    let(:company) { create(:company, ident: 'something-not-in-the-good-list') }
    let(:category) { create(:category, ident: '4fb3e303', name: 'Private Krankenversicherung') }
    let(:combo_category) { create(:combo_category, included_categories: [category, create(:category)]) }
    let!(:product) { create(:product, premium_price: 280.00, premium_period: :month, mandate: mandate, plan: create(:plan, company: company, category: category)) }

    it_behaves_like 'a robo advice for method', :private_health_insurance

    it 'sends the appropriate text' do
      product.update!(contract_started_at: 5.years.ago - 1.day)
      subject.private_health_insurance

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.private_health_insurance.five_year_contract'), product)
      product.reload

      expect(product.advices.first.content).to eq(expected_text)
    end

    context 'for regular PKV category' do
      it_behaves_like 'pkv tests'
    end

    context 'for combo catgory containing PKV' do
      before do
        product.plan.update!(category: combo_category)
      end

      it_behaves_like 'pkv tests'
    end
  end
end
