# frozen_string_literal: true

require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new("/dev/null")) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context "accident insurance (Unfallversicherung)" do
    let(:category) { create(:category, ident: "cf064be0", name: "Unfallversicherung") }
    let(:company) { create(:company, ident: RoboAdvisor::GOOD_INSURANCE_ACCIDENT.sample) }

    let!(:product) do
      create(:product, premium_price: 300.00, premium_period: :year, mandate: mandate,
                       plan: create(:plan, category: category, company: company))
    end

    it_behaves_like "a robo advice for method", :accident_insurance

    it "send out the catch all advice, when the product is from some other company" do
      company.update!(ident: "something-that-does-not-exist")

      expect { subject.accident_insurance }.to change(product.interactions, :count).by(2)

      advice_text_ident = "robo_advisor.accident_insurance.replace_insurance"
      expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
      expect(product.advices.first.content).not_to include(advice_text_ident)
      expect(product.advices.first.content).to eq(expected_text)
    end

    RoboAdvisor::GOOD_INSURANCE_ACCIDENT.each do |company_ident|
      it "sends out the advice when product is from company #{company_ident}" do
        company.update!(ident: company_ident)

        expect { subject.accident_insurance }.to change(product.interactions, :count).by(2)

        advice_text_ident = "robo_advisor.accident_insurance.good_insurance"
        expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
        expect(product.advices.first.content).not_to include(advice_text_ident)
        expect(product.advices.first.content).to eq(expected_text)
      end
    end
  end
end
