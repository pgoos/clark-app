# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Partners::Mam::MilesCredited do
  context "mandates with miles credit" do
    subject do
      Domain::Partners::Mam::MilesCredited.mandates_with_new_miles.all
    end

    let!(:mandate_no_miles) { create(:mandate) }
    let(:mandate_miles) { create(:mandate) }
    let(:mandate_old_miles) { create(:mandate) }
    let(:mandate_welcome_miles) { create(:mandate) }
    let(:mandate_0_miles) { create(:mandate) }

    before do
      create(:loyalty_booking, mandate: mandate_miles, amount: 2)
      create(:loyalty_booking, mandate: mandate_old_miles, created_at: 25.hours.ago)
      create(:loyalty_booking, mandate: mandate_0_miles, amount: 0)
      create(:loyalty_booking, mandate: mandate_welcome_miles,
                               bookable: mandate_welcome_miles)
    end

    it "includes a recent mandate with miles" do
      expect(subject).to include(mandate_miles)
    end

    it "do not include a mandate who received miles more than 24 hours ago" do
      expect(subject).not_to include(mandate_old_miles)
    end

    it "do not include a mandate with no miles" do
      expect(subject).not_to include(mandate_no_miles)
    end

    it "does not include a mandate with welcome booking" do
      expect(subject).not_to include(mandate_welcome_miles)
    end
  end
end
