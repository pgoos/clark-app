require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"

  subject { RoboAdvisor.new(Logger.new("/dev/null")) }

  let(:device) { create(:device, push_enabled: true) }
  let(:user) { create(:user, devices: [device]) }
  let(:mandate) { create(:mandate, user: user, state: "accepted") }
  let!(:admin) { create(:advice_admin) }

  context "Animal Health Insurance" do
    let(:category) do
      create(:category, ident: described_class::ANIMAL_HEALTH_INSURANCE)
    end

    let(:plan) { create(:plan, category: category) }
    let!(:product) do
      create(:product, premium_price:   33.00,
                         premium_period:  :year,
                         mandate:         mandate,
                         plan:            plan)
    end

    it_behaves_like "a robo advice for method", :animal_health_insurance

    it "advices all products in the list" do
      expect do
        subject.animal_health_insurance
      end.to change { product.interactions.count }

      i18n_key = "robo_advisor.animal_health_insurance.catch_all"
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to match(/translation missing/)
      expect(product.advices.first.content).not_to include(i18n_key)
    end
  end
end
