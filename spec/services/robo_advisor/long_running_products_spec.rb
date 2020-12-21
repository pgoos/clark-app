require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Diverse Versicherungen (Langläufer)' do
    RoboAdvisor::CATEGORIES_TO_ADVICE_WHEN_LONG_RUNNING.each do |category_ident|
      let!(:category) { create(:category, ident: category_ident) }
      let!(:product) do
        create :product, contract_ended_at: 2.years.from_now,
                         premium_price: 23.00,
                         premium_period: :year,
                         mandate: mandate,
                         plan: create(:plan, category: category)
      end

      context "for category ident #{category_ident}" do
        it_behaves_like 'a robo advice for method', :long_running_products

        it 'sends the appropriate text' do
          subject.long_running_products

          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.general.long_running.text'), product)
          expect(product.advices.first.content).to eq(expected_text)
        end

        it 'does not send the advice when the product ends within the next 15 months' do
          product.update!(contract_ended_at: 12.months.from_now)

          expect {
            subject.long_running_products
          }.not_to(change { product.interactions.count })
        end

        it 'sends the advice when the category is included in a combo product' do
          combo_category = create(:combo_category, included_categories: [category])
          product.update!(plan: create(:plan, category: combo_category))

          expect(product.category).to_not eq(category)

          expect {
            subject.long_running_products
          }.to change { product.interactions.count }.by(2)
        end
      end
    end
  end
end
