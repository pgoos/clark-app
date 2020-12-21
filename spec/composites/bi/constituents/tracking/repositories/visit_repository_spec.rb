# frozen_string_literal: true

require "rails_helper"

RSpec.describe BI::Constituents::Tracking::Repositories::VisitRepository, :integration do
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

    it "updates umt attributes" do
      visit = create(:tracking_visit)
      r_visit = repo.update!(visit.id, attributes)
      expect(r_visit).to be_kind_of BI::Constituents::Tracking::Entities::Visit
      expect(r_visit.utm_content).to eq "adgroup 1"
      expect(r_visit.utm_source).to eq "network 2"
      expect(r_visit.utm_term).to eq "creative 4"
      expect(r_visit.utm_campaign).to eq "campaign 3"
    end
  end
end
