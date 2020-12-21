# frozen_string_literal: true

require "rails_helper"

RSpec.describe BI::Constituents::Tracking::Repositories::CustomerRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#update!" do
    let(:attributes) do
      {
        "adgroup" => "adgroup 1",
        "network" => "network 2",
        "campaign" => "campaign 3",
        "creative" => "creative 4"
      }
    end

    it "updates lead adjust attributes" do
      lead = create(:lead)
      repo.update!(lead.mandate_id, attributes)
      lead.reload
      expect(lead.adjust["adgroup"]).to eq "adgroup 1"
      expect(lead.adjust["network"]).to eq "network 2"
      expect(lead.adjust["creative"]).to eq "creative 4"
      expect(lead.adjust["campaign"]).to eq "campaign 3"
    end

    it "updates user adjust attributes" do
      user = create(:user, :with_mandate, adjust: { adgroup: "adgroup 0", foo: "bar" })
      repo.update!(user.mandate_id, attributes)
      user.reload
      expect(user.adjust["adgroup"]).to eq "adgroup 1"
      expect(user.adjust["network"]).to eq "network 2"
      expect(user.adjust["creative"]).to eq "creative 4"
      expect(user.adjust["campaign"]).to eq "campaign 3"
      expect(user.adjust["foo"]).to eq "bar"
    end
  end
end
