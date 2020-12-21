# frozen_string_literal: true

require "rails_helper"

describe Robo::Advices::TemplateBuilder do
  subject { described_class.new }

  let(:mandate)    { build_stubbed :mandate }
  let(:product)    { build_stubbed :product, :year_premium, premium_price: 1000, plan: plan }
  let(:plan)       { build_stubbed :plan, company: company, category: category }
  let(:company)    { build_stubbed :company, name: "COMPANY" }
  let(:category)   { build_stubbed :category_phv }
  let(:subcompany) { build_stubbed :subcompany, company: company, revenue_generating: true }

  before do
    allow(Category).to receive(:phv).and_return category
    allow(Product).to receive(:find).with(product.id).and_return product

    allow(product).to receive(:company).and_return company
    allow(product).to receive(:category).and_return category
    allow(product).to receive(:subcompany).and_return subcompany
    allow(category).to receive(:questionnaire_identifier).and_return "abc123"
  end

  shared_examples "roboadvisor template" do |rule_id|
    it do
      template = subject.(rule_id, product)
      expect(template.classification).to eq :keeper
      expect(template.cta.link).to eq "/de/app/questionnaire/abc123"
      expect(template.cta.text).to eq "Angebot anfordern"
      expect(template.text).to be_present
    end
  end

  context "with PHV" do
    let(:category) { build_stubbed :category_phv }

    it_behaves_like "roboadvisor template", "2.6.b"
  end

  context "with legal protection" do
    let(:category) { build_stubbed :category_legal }

    it_behaves_like "roboadvisor template", "3.1"
  end

  context "with accident insurance" do
    it_behaves_like "roboadvisor template", "5.2"
  end

  context "with home insurance" do
    let(:category) { build_stubbed :category_home_insurance }
    let(:product) { build_stubbed(:product, plan: plan, contract_ended_at: 1.month.from_now) }

    it_behaves_like "roboadvisor template", "14.2"
  end

  context "with car insurance" do
    let(:category) { build_stubbed :category_car_insurance }
    let(:product)  { build_stubbed(:product, plan: plan, contract_ended_at: 1.month.from_now) }

    it_behaves_like "roboadvisor template", "101.2"
  end

  context "with household" do
    let(:category) { build_stubbed :category_hr }

    it_behaves_like "roboadvisor template", "4.1"
  end

  context "with dental" do
    let(:category) { build_stubbed :category_dental }

    it_behaves_like "roboadvisor template", "12.1"
  end

  context "with travel health" do
    let(:category) { build_stubbed :category_travel_health }

    it_behaves_like "roboadvisor template", "11.1"
  end

  context "with disability insurance" do
    let(:category) { build_stubbed :bu_category }
    let(:product)  { build_stubbed(:product, plan: plan, contract_ended_at: 1.month.from_now) }

    it_behaves_like "roboadvisor template", "7.2"
  end

  context "with risk life" do
    let(:category) { build_stubbed :category_risk_life }

    it_behaves_like "roboadvisor template", "16.3"
  end

  context "with private health" do
    let(:category) { build_stubbed :category_pkv, :advice_enabled }

    it_behaves_like "roboadvisor template", "18.1"
  end

  context "with roadsie assistance" do
    let(:category) { build_stubbed :category_roadside_assistance, :advice_enabled }

    it_behaves_like "roboadvisor template", "118.1"
  end

  context "with riester" do
    let(:category) { build_stubbed :category_riester, :advice_enabled }

    it_behaves_like "roboadvisor template", "107.1"
  end

  context "with retirement" do
    let(:category) { build_stubbed :category_retirement, :advice_enabled }

    it_behaves_like "roboadvisor template", "29.1"
  end
end
