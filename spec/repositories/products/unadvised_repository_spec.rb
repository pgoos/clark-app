# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::UnadvisedRepository do
  describe "#all" do
    subject { Products::UnadvisedRepository.new(company_ident: "correct_ident") }

    let(:company) { create(:company, ident: company_ident) }
    let!(:product) { create(:product, company: company) }

    context "when product with ident exists" do
      let(:company_ident) { "correct_ident" }

      it "returns correct data" do
        expect(subject.all).to eq([product])
      end
    end

    context "when product with ident doesn't exist" do
      let(:company_ident) { "incorrect_ident" }

      it "returns empty list" do
        expect(subject.all).to eq([])
      end
    end
  end
end
