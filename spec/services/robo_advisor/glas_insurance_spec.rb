require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  %w(06f05bb7 f47677cc).each do |glas_ident|
    context "Glas-Versicherung (ident: #{glas_ident})" do
      let(:category) { create(:category, ident: glas_ident, name: 'Glas-Versicherung') }
      let!(:hrv_category) { create(:category, ident: 'e251294f', name: 'Hausratversicherung') }
      let!(:product) { create(:product, premium_price: 60.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

      it_behaves_like 'a robo advice for method', :glas_insurance

      it 'sends the appropriate text for > 45€ yearly' do
        expect do
          subject.glas_insurance
        end.to change { product.interactions.count }.by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.glas_insurance.too_expensive'), product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it 'sends the appropriate text if the customer also has a Hausratversicherung' do
        create(:product, mandate: mandate, plan: create(:plan, category: hrv_category))

        expect do
          subject.glas_insurance
        end.to change { product.interactions.count }.by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.glas_insurance.with_home_insurance'), product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it 'sends the appropriate text if the customer also has a Combo including Hausratversicherung' do
        combo_category = create(:combo_category, included_categories: [hrv_category])
        create(:product, mandate: mandate, plan: create(:plan, category: combo_category))

        expect do
          subject.glas_insurance
        end.to change { product.interactions.count }.by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.glas_insurance.with_home_insurance'), product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it 'does not send an advice when product costs < 45€ and customer does not have Hausratversicherung' do
        product.update!(premium_price: 40.0)

        expect do
          subject.glas_insurance
        end.not_to change { product.interactions.count }
      end
    end
  end
end
