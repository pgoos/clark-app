require 'rails_helper'
require 'spec_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:insurance_name) { 'Privathaftpflicht- & Tierhalter-Haftpflichtversicherung' }

  let(:subject) { described_class.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let(:company) { create(:company, ident: 'something-not-in-the-list') }
  let(:category) { create(:category, ident: 'afe225d9', name: insurance_name) }
  let!(:admin) { create(:advice_admin) }

  context 'advising Privathaftpflicht- & Tierhalter-Haftpflichtversicherung' do
    let!(:product) { create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate,
                                      plan: create(:plan, company: company, category: category)) }

    options = {custom_identifier: 'private_liability_insurance_with_animal_ownership_65_1'}
    it_behaves_like 'a robo advice for method', :private_liability_insurance_with_animal_ownership, options
  end

  context 'Rule 65.1 - Privathaftpflicht- & Tierhalter-Haftpflichtversicherung' do
    context 'premium is >= 120 annual for rule (65.1)' do
      let!(:product_advisable) { create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate,
                              plan: create(:plan, company: company, category: category)) }


      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.saving_advice',
                      'private_liability_insurance_with_animal_ownership_65_1'
    end

    context 'premium IS NOT >= 120 annual for rule (65.1)' do
      let!(:product_non_advisable) { create(:product, premium_price: 10.00, premium_period: :year, mandate: mandate,
                              plan: create(:plan, company: company, category: category)) }

      it 'sends no interaction' do
        expect do
          subject.private_liability_insurance_with_animal_ownership
        end.to change(product_non_advisable.interactions, :count).by(0)
      end
    end
  end

  context 'Rule 65.2 - Privathaftpflicht- & Tierhalter-Haftpflichtversicherung' do
    let(:category_with_features) do
      create(:category, ident: 'afe225d9', name: 'Privathaftpflichtversicherung', coverage_features: [
          CoverageFeature.new(identifier: 'money_dckngssmmprsnnschdn_c4d961', name: 'Deckungssumme Personenschäden',
                              definition: 'Deckungssumme Personenschäden', value_type: 'Money'),

          CoverageFeature.new(identifier: 'money_dckngssmmschschdn_4765ee', name: 'Deckungssumme Sachschäden',
                              definition: 'Deckungssumme Sachschäden"', value_type: 'Money'),

          CoverageFeature.new(identifier: 'money_dckngssmmvrmgnsschdn_a4c482', name: 'Deckungssumme Vermögensschäden',
                              definition: 'Deckungssumme Vermögensschäden', value_type: 'Money')
      ])
    end

    let(:plan) do
      create(:plan, company: company, category: category_with_features)
    end

    context 'Personenschäden coverage is bellow 5 million (65.2)' do
      let!(:product_advisable) do
        create(:product, premium_price: 100.00, premium_period: :year, mandate: mandate, plan: plan,
               coverages: {
                   'money_dckngssmmprsnnschdn_c4d961' => ValueTypes::Money.new(4_000_000, 'EUR')
               })
      end

      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.coverage_advice',
                      'private_liability_insurance_with_animal_ownership_65_2_person'
    end

    context 'Sachschäden coverage is bellow 5 million (65.2)' do
      let!(:product_advisable) do
        create(:product, premium_price: 100.00, premium_period: :year, mandate: mandate, plan: plan,
               coverages: {
                   'money_dckngssmmschschdn_4765ee' => ValueTypes::Money.new(4_000_000, 'EUR')
               })
      end

      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.coverage_advice',
                      'private_liability_insurance_with_animal_ownership_65_2_property'
    end

    context 'Vermögensschäden coverage is bellow 5 million (65.2)' do
      let!(:product_advisable) do
        create(:product, premium_price: 100.00, premium_period: :year, mandate: mandate, plan: plan,
               coverages: {
                   'money_dckngssmmvrmgnsschdn_a4c482' => ValueTypes::Money.new(4_000_000, 'EUR')
               })
      end

      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.coverage_advice',
                      'private_liability_insurance_with_animal_ownership_65_2_pecuniary'
    end

    context 'Vermögensschäden coverage is bellow 5 million but premium is above 120, advise (65.1)' do
      let!(:product_advisable) do
        create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: plan,
               coverages: {
                   'money_dckngssmmvrmgnsschdn_a4c482' => ValueTypes::Money.new(4_000_000, 'EUR')
               })
      end

      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.saving_advice',
                      'private_liability_insurance_with_animal_ownership_65_1'
    end
  end

  context 'Rule 65.3 - Privathaftpflicht- & Tierhalter-Haftpflichtversicherung' do
    context 'Bayerische Versicherung insurer' do
      let(:plan_bayerische) do
        create(:plan, company: create(:company, ident: 'bayerc75742'), category: category)
      end

      let!(:product_advisable) do
        create(:product, premium_price: 100.00, premium_period: :year, mandate: mandate, plan: plan_bayerische)
      end

      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.company_advice',
                      'private_liability_insurance_with_animal_ownership_65_3'
    end

    context 'Haftpflichtkasse Darmstadt insurer' do
      let(:plan_hapftflich) do
        create(:plan, company: create(:company, ident: 'haftpe6e5c1'), category: category)
      end

      let!(:product_advisable) do
        create(:product, premium_price: 100.00, premium_period: :year, mandate: mandate, plan: plan_hapftflich)
      end

      it_behaves_like 'an advice for private_liability_insurance_with_animal_ownership',
                      'robo_advisor.private_liability_insurance_with_animal_ownership.company_advice',
                      'private_liability_insurance_with_animal_ownership_65_3'
    end
  end
end
