require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  subject { RoboAdvisor.new(Logger.new("/dev/null")) }

  let(:device) { create(:device, push_enabled: true) }
  let(:user) { create(:user, devices: [device]) }
  let(:mandate) { create(:mandate, user: user) }
  let!(:admin) { create(:advice_admin) }

  context "Direkt Insurance" do
    let(:category) { create(:category, ident: RoboAdvisor::DIRECT_INSURANCE_IDENT) }

    let(:plan) { create(:plan, category: category) }
    let!(:product) do
      create(:product, premium_price: 1.01,
                         premium_period: :year,
                         mandate: mandate,
                         plan: plan)
    end

    it_behaves_like "a robo advice for method", :direct_insurance

    it "advices all products more than 1.00 euro" do
      expect do
        subject.direct_insurance
      end.to change { product.interactions.count }

      i18n_key = "robo_advisor.direct_insurance.premium_more_than_one"
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to match(/translation missing/)
      expect(product.advices.first.content).not_to include(i18n_key)
    end

    it "does not advice on products with price less than 1 euro" do
      product.update!(premium_price: 0.10)

      expect do
        subject.direct_insurance
      end.to change { product.interactions.count }

      i18n_key = "robo_advisor.direct_insurance.catch_all"
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      product.reload
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to match(/translation missing/)
      expect(product.advices.first.content).not_to include(i18n_key)
    end
  end
end


