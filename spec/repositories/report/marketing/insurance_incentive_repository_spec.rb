# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report::Marketing::InsuranceIncentiveRepository do
  subject { described_class.new }

  let(:source_data) do
    {adjust: {network: "mam", campaign: "tmx-2430", adgroup: "ad", creative: "creative", medium: "medium"}}
  end
  let!(:user) { create(:user, source_data: source_data) }
  let!(:mandate) { create(:mandate, :accepted, user: user, birthdate: "1979-04-22") }
  let!(:business_event) { create(:business_event, entity: mandate, action: "accept") }
  let(:address) { create(:address, mandate: mandate) }

  let(:expected_result) do
    {
      "mandate_id" => mandate.id,
      "email" => user.email,
      "first_name" => mandate.first_name,
      "last_name" => mandate.last_name,
      "birthdate" => mandate.birthdate.strftime("%F"),
      "gender" => mandate.gender,
      "street" => address.street,
      "house_number" => address.house_number,
      "zipcode" => address.zipcode,
      "city" => address.city,
      "network" => "mam",
      "adgroup" => "ad",
      "campaign" => "tmx-2430",
      "creative" => "creative",
      "medium" => "medium",
      "accepted_at" => business_event.created_at.strftime("%F")
    }
  end

  describe "#all" do
    it "returns the correct result" do
      expect(subject.all.size).to eq(1)

      expect(subject.all.first["mandate_id"]).to eq(mandate.id)
      expect(subject.all.first).to eq(expected_result)
    end
  end
end
