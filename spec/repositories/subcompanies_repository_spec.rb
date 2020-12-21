# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubcompaniesRepository do
  let(:subcompany) { create(:subcompany) }

  context "#find" do
    it "returns an instance of Structs::Subcompany" do
      struct = described_class.find(subcompany.id)

      expect(struct).to be_kind_of(Structs::Subcompany)
    end

    it "returns correct values" do
      struct = described_class.find(subcompany.id)

      expect(struct.id).to eq(subcompany.id)
      expect(struct.order_email).to eq(subcompany.order_email)
    end
  end
end
