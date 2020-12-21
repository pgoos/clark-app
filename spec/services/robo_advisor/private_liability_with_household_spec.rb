require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  subject { RoboAdvisor.new(Logger.new("/dev/null")) }

  let(:device) { create(:device, push_enabled: true) }
  let(:user) { create(:user, devices: [device]) }
  let(:mandate) { create(:mandate, user: user, state: "accepted") }
  let!(:admin) { create(:advice_admin) }

  context "Privathaftpflich + Hausrat" do
    let(:category) do
      create(:category, ident: described_class::PHV_HAUSRAT_MULTI_CATEGORY_IDENTS.sample)
    end

    let(:plan) { create(:plan, category: category) }
    let!(:product) do
      create(:product, premium_price:   33.00,
                         premium_period:  :year,
                         mandate:         mandate,
                         plan:            plan)
    end

    it_behaves_like "a robo advice for method", :private_liability_with_household

    it "advices all products in the list" do
      expect do
        subject.private_liability_with_household
      end.to change { product.interactions.count }

      i18n_key = "robo_advisor.private_liability_with_household.catch_all"
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to match(/translation missing/)
      expect(product.advices.first.content).not_to include(i18n_key)
    end
  end
end
