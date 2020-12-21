require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Reisekrankenversicherung' do
    let(:category) { create(:category, ident: '875823e3', name: 'Reisekrankenversicherung') }

    let!(:product) { create(:product, premium_price: 33.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :travel_health_insurance

    it 'sends the appropriate text for price < 40€' do
      subject.travel_health_insurance

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.travel_health_insurance.ok'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not advice product if price > 40€' do
     product.update!(premium_price: 50.0)

      expect do
        subject.travel_health_insurance
      end.not_to change { product.interactions.count }
    end

    context 'adac company' do
      let(:company) { create(:company) }
      before { product.update!(premium_price: 50.0, company: company) }

      it 'sends particular advice for company ADAC Versicherung' do
        company.update!(ident: "adacv8ee563")

        expect do
          subject.travel_health_insurance
        end.to change(product.interactions, :count).by(2)

        advice_text_ident = 'robo_advisor.travel_health_insurance.adac'
        expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
        product.reload

        expect(product.advices.first.content).not_to include(advice_text_ident)
        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.content).to include('ADAC')
      end
    end

    # todo test interaction count change (push + mail = 2)
  end
end
