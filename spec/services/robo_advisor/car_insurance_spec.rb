require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'KFZ-Verischerungen (alle unter Umbrella)' do
    let(:category_1) { create(:category) }
    let(:category_2) { create(:category) }
    let!(:kfz_haftpflicht) { create(:category, ident: 'd9c5a3fe', name: 'KFZ-Haftpflicht') }
    let!(:umbrella_category) { create(:umbrella_category, ident: '58680af3', included_categories: [category_1, category_2]) }

    let!(:product) { create(:product, contract_ended_at: 6.months.from_now, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category_1)) }

    it_behaves_like 'a robo advice for method', :car_insurance

    RoboAdvisor::GOOD_INSURANCE_CAR.each do |company_ident|
      it "sends out the appropriate advice when the company is #{company_ident}" do
        company = create(:company, ident: company_ident)
        product.plan.update!(company: company)

        expect do
          subject.car_insurance
        end.to change(product.interactions, :count).by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.car_insurance.good_insurance'), product)
        expect(product.advices.first.content).to eq(expected_text)
      end
    end

    it 'does not advice product if there\'s less than 4 months between created/contract_ended' do
      product.update!(created_at: product.contract_ended_at - 4.months + 1.day)

      expect do
        subject.car_insurance
      end.not_to change(product.interactions, :count)
    end

    it 'sends the appropriate text for contracts with 4 months till contract end' do
      subject.car_insurance

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.car_insurance.four_months_till_end'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'advices product when falsely created with umbrella category (LEGACY)' do
      product.destroy
      product = create(:product, contract_ended_at: 6.months.from_now, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: umbrella_category))

      expect do
        subject.car_insurance
      end.to change(product.interactions, :count).by(2)
    end
  end
end
