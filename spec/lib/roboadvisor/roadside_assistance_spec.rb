# frozen_string_literal: true

require "rails_helper"
require "roboadvisor"

RSpec.describe "integration test for roadside assistance", type: :integration do
  describe ".process" do
    subject { Roboadvisor.process(product.id) }

    let(:plan) { create :plan, category: category, company: company }
    let(:company) { create :company }
    let(:product) { create :product, plan: plan }
    let(:subcompany) { create :subcompany, company: company }
    let(:category) { create :category_roadside_assistance }

    context "with company ident of ADAC" do
      let(:company) { create :company, ident: "adacv8ee563" }

      it { is_expected.to eq "118.1" }
    end

    context "when no other rule applies" do
      let(:company) { create :company }

      it { is_expected.to eq "118.2" }
    end
  end
end
