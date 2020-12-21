# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Mortgage::LeadsRepository, :integration do
  describe ".fields_order" do
    let(:expected_fields) do
      %w[
        mandate_id
        first_name
        last_name
        mandate_created_at
        phone_number
        age
        grossincome
        demand_estate_answer
        demand_financing_answer
        answer_date
      ]
    end

    it "returns fields_order" do
      expect(described_class.fields_order).to eq(expected_fields)
    end
  end

  describe "#all" do
    let!(:madate) { create :mandate }

    it "runs query" do
      service = described_class.new

      allow(service).to receive(:query).and_return("select * from mandates;")
      expect(service.all.size).to eq(Mandate.count)
    end
  end
end
