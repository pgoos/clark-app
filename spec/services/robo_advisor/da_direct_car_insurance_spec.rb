require 'rails_helper'
require 'lifters/offers/da_direct/config'

RSpec.describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include ActionView::Helpers::NumberHelper

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, state: 'accepted', user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'KFZ-Verischerungen (DA Direkt)' do
    let(:category_1) { create(:category) }
    let(:category_2) { create(:category) }
    let!(:kfz_haftpflicht) { create(:category, ident: 'd9c5a3fe', name: 'KFZ-Haftpflicht') }
    let!(:umbrella_category) { create(:umbrella_category, ident: '58680af3', included_categories: [category_1, category_2]) }

    let!(:product) { create(:product, contract_ended_at: 6.months.from_now, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category_1)) }

    let(:data_attribute) do
      {
          gender: mandate.gender,
          birthdate: mandate.birthdate,
          premium: ValueTypes::Money.new(product.premium_price.to_f, 'EUR'),
          replacement_premium: ValueTypes::Money.new((product.premium_price - ::Money.new(1001, 'EUR')).to_f, 'EUR'),
          premium_period: :year,
      }
    end

    let!(:product_partner_datum) { create(:product_partner_datum, product: product, data: data_attribute.merge('VU' => 'DA Direkt Mein Tarif Komfort (Werkstattbindung)')) }
    let!(:product_partner_datum_rejected) { create(:product_partner_datum, product: product, data: data_attribute.merge('VU' => 'other')) }

    it_behaves_like "a robo advice for method", :kfz_da_direct, skip_unadviced_check: true, skip_age_check: true,
                                                                skip_updated_advice_check: true

    it 'sends out the appropriate advice when the saving is greater than 10 €' do
      expect do
        subject.kfz_da_direct
      end.to change(product.interactions, :count).by(2)

      product_partner_datum.reload

      saving = product_partner_datum.possible_saving
      advice = product.advices.first

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.car_insurance_da_direkt.too_expensive'), product, saving: saving)
      content = advice.content
      expect(content).to eq(expected_text)
      expect(content).to match(/#{number_with_precision(saving, delimiter: '.', precision: 2)} Euro/)

      expect(advice.cta_link).to eq("de/app/manager/products/#{product.id}/appointment")

      expect(product_partner_datum).to be_chosen
    end

    it 'does not advice when the saving is smaller than 10 €' do
      data = product_partner_datum.data
      data[:replacement_premium] = ValueTypes::Money.new((product.premium_price - ::Money.new(999, 'EUR')).to_f, 'EUR')
      product_partner_datum.data = data
      product_partner_datum.save
      product_partner_datum.reload
      expect(product_partner_datum.replacement_premium).to eq(::Money.new(11001, 'EUR'))

      expect do
        subject.kfz_da_direct
      end.to change(product.interactions, :count).by(2)

      product_partner_datum.reload

      advice = product.advices.first

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.car_insurance_da_direkt.good_insurance'), product)
      content = advice.content
      expect(content).to eq(expected_text)
      expect(content).to_not match(/\#{unternehmen}/)

      expect(advice.cta_link).to be_blank

      expect(product_partner_datum).to be_deferred
      expect(product_partner_datum.reason_to_defer).to eq('robo_advisor.car_insurance_da_direkt.defer_reason.saving_below_10')
    end

    it 'should persist an i18n key for the defer reason sold_by_us' do
      product.update!(sold_by: Product::SOLD_BY_US)

      subject.kfz_da_direct

      product_partner_datum.reload
      expect(product_partner_datum).to be_deferred
      expect(product_partner_datum.reason_to_defer).to eq('robo_advisor.car_insurance_da_direkt.defer_reason.sold_by_us')
    end

    it 'should persist an i18n key for the defer reason no email' do
      mandate.update_attributes(user: nil)

      subject.kfz_da_direct

      product_partner_datum.reload
      expect(product_partner_datum).to be_deferred
      expect(product_partner_datum.reason_to_defer).to eq('robo_advisor.car_insurance_da_direkt.defer_reason.no_email')
    end

    it 'should persist an i18n key for the defer reason no email' do
      mandate.update_attributes(state: 'revoked')

      subject.kfz_da_direct

      product_partner_datum.reload
      expect(product_partner_datum).to be_deferred
      expect(product_partner_datum.reason_to_defer).to eq('robo_advisor.car_insurance_da_direkt.defer_reason.mandate_revoked')
    end

    it 'should have all necessary i18n keys' do
      product.update!(sold_by: Product::SOLD_BY_US)
      mandate.update_attributes(user: nil)
      mandate.update_attributes(state: 'revoked')

      subject.kfz_da_direct

      product_partner_datum.reload
      expect(product_partner_datum).to be_deferred
      expect(product_partner_datum.reason_to_defer.split(',').size).to eq(3)
    end

    it 'should defer all data, which does not match the intended plan' do
      subject.kfz_da_direct

      product_partner_datum_rejected.reload
      expect(product_partner_datum_rejected).to be_deferred
      expect(product_partner_datum_rejected.reason_to_defer).to eq('robo_advisor.car_insurance_da_direkt.defer_reason.not_chosen_due_to_price')
    end
  end
end
