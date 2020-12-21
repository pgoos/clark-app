# frozen_string_literal: true

require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new("/dev/null")) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context "basic pension fund (Basis-Rentenversicherung)" do
    let(:category) { create(:category, ident: "63cfb93c", name: "Basis-Rentenversicherung") }
    let!(:product) { create(:product, contract_started_at: 2.years.ago, premium_price: 850.00, premium_period: :year, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like "a robo advice for method", :basic_pension_fund

    it "sends the appropriate text if yearly contribution is too low" do
      expect do
        subject.basic_pension_fund
      end.to change { product.interactions.count }.by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.basic_pension_fund.low_contribution'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it "sends the appropriate text if yearly contribution is high enough and product is 5 years old" do
      product.update!(premium_price: 1000.00, contract_started_at: 6.years.ago)
      expect do
        subject.basic_pension_fund
      end.to change { product.interactions.count }.by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.basic_pension_fund.five_year_contract'), product)
      product.reload
      expect(product.advices.first.content).to eq(expected_text)
    end

    it "does not send out an advice when the product is on hold" do
      product.update!(premium_price: 0, premium_period: "none")
      expect do
        subject.basic_pension_fund
      end.not_to change { product.interactions.count }
    end

    it "does not send out an advice when the product is too young and well contributed to" do
      product.update!(premium_price: 1000.00)

      expect do
        subject.basic_pension_fund
      end.not_to change { product.interactions.count }
    end
  end
end
