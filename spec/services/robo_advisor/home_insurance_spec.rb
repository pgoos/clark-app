require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Wohngebäudeversicherung' do
    let(:company) { create(:company) }
    let(:category) { create(:category, ident: RoboAdvisor::HOUSE_INSURANCE_IDENT, name: 'Wohngebäudeversicherung') }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, company: company, category: category)) }

    context 'with product ending' do
      let!(:product) { create(:product, mandate: mandate, plan: create(:plan, company: company, category: category), contract_ended_at: 10.months.from_now) }
      it_behaves_like 'a robo advice for method', :home_insurance, skip_identifier: true
    end

    it 'sends out an advice for products ending between today and 15.months.from_now' do
      product.update!(contract_ended_at: 10.months.from_now)

      expect do
        subject.home_insurance
      end.to change(product.interactions, :count)

      i18n_key = 'robo_advisor.home_insurance.about_to_end'
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      product.reload

      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to include(i18n_key)
    end

    it 'sends out an advice for products from Allianz' do
      company.update!(ident: "allia8c23e2")

      expect do
        subject.home_insurance
      end.to change(product.interactions, :count)

      i18n_key = 'robo_advisor.home_insurance.allianz'
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to include(i18n_key)
    end

    it 'sends the catch all advice for products that do not follow a rule' do
      expect do
        subject.home_insurance
      end.to change(product.interactions, :count)

      i18n_key = 'robo_advisor.home_insurance.catch_all'
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to include(i18n_key)
    end

    RoboAdvisor::GOOD_INSURANCE_HOME.each do |company_ident|
      it "sends out good company advice for products from company #{company_ident}" do
        company.update!(ident: company_ident)

        expect do
          subject.home_insurance
        end.to change(product.interactions, :count).by(2)

        i18n_key = 'robo_advisor.home_insurance.company_list'
        expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.content).not_to include(i18n_key)
      end
    end

  end
end
