require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Berufsunfähigkeitsversicherung' do
    let(:company) { create(:company, ident: 'something-not-in-the-list') }
    let(:category) do
      create(:category, ident: '3d439696', name: 'Berufsunfähigkeitsversicherung', coverage_features: [
        CoverageFeature.new(identifier: 'mntlcfda086f6f09f928d', name: 'Monatliche Berufsunfähigkeitsrente', definition: 'Monatliche Berufsunfähigkeitsrente', value_type: 'Money')
      ])
    end

    let!(:product) { create(:product, coverages: { 'mntlcfda086f6f09f928d' => ValueTypes::Money.new(900, 'EUR') }, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, company: company, category: category)) }

    it_behaves_like 'a robo advice for method', :disability_insurance

    it 'send catch all advice when no coverage features' do
      product.update!(coverages: {})

      expect do
        subject.disability_insurance
      end.to change(product.interactions, :count).by(2)

      advice_text_ident = 'robo_advisor.disability_insurance.catch_all'
      expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
      product.reload

      expect(product.advices.first.content).not_to include(advice_text_ident)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'sends the appropriate advice for BU Rente < 1.000€' do
      subject.disability_insurance

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.disability_insurance.bad_coverage'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'send catch all advice when does not fall in any category' do
      product.update!(coverages: { "mntlcfda086f6f09f928d" => ValueTypes::Money.new(1_500, "EUR") })

      expect do
        subject.disability_insurance
      end.to change(product.interactions, :count).by(2)

      advice_text_ident = 'robo_advisor.disability_insurance.catch_all'
      expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
      product.reload

      expect(product.advices.first.content).not_to include(advice_text_ident)
      expect(product.advices.first.content).to eq(expected_text)
    end

    context 'good company advice' do
      before { product.update!(coverages: { "mntlcfda086f6f09f928d" => ValueTypes::Money.new(1500, "EUR") }) }

      it "sends out good company advice for products from Nürnberger Versicherungsgruppe" do
        company.update!(ident: "nrnbe80515b")

        expect do
          subject.disability_insurance
        end.to change(product.interactions, :count).by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.disability_insurance.good_insurance_nurnberger'), product)
        product.reload

        expect(product.advices.first.content).to eq(expected_text)
      end

      RoboAdvisor::GOOD_INSURANCE_DISABILITY.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.disability_insurance
          end.to change(product.interactions, :count).by(2)

          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.disability_insurance.good_insurance_generic'), product)
          product.reload

          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end
  end
end
