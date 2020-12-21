# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Tracking::RegulateAdjustEvents do
  describe ".fill_mandate_in_previous_to" do
    let(:mandate) { create :mandate }
    let(:event)   { create :tracking_adjust_event, adid: "ADID", mandate_id: mandate.id }

    it "fills mandate id in previous events" do
      previous = create :tracking_adjust_event, :install, adid: "ADID", created_at: 1.minute
      described_class.fill_mandate_in_previous_to!(event)
      expect(previous.reload.mandate).to eq mandate
    end

    context "when event adid is blank" do
      let(:event) { create :tracking_adjust_event, mandate_id: mandate.id }

      it "does nothing" do
        expect(described_class.fill_mandate_in_previous_to!(event)).to be_nil
      end
    end

    context "when event mandate is blank" do
      let(:event) { create :tracking_adjust_event, adid: "ADID" }

      it "does nothing" do
        expect(described_class.fill_mandate_in_previous_to!(event)).to be_nil
      end
    end

    context "when previous event came later than 30 minutes ago" do
      it "does not touch previous event" do
        previous = create :tracking_adjust_event, :install, adid: "ADID", created_at: 31.minutes
        expect { described_class.fill_mandate_in_previous_to!(event) }
          .not_to change(previous, :updated_at)
      end
    end

    context "when previous event already has mandate" do
      it "does not touch previous event" do
        previous = create :tracking_adjust_event,
                          :install,
                          mandate:    mandate,
                          adid:       "ADID",
                          created_at: 1.minute

        expect { described_class.fill_mandate_in_previous_to!(event) }
          .not_to change(previous, :updated_at)
      end
    end

    context "with unrelated previous event" do
      it "does not touch previous event" do
        previous = create :tracking_adjust_event, :install, adid: "BAR", created_at: 1.minute
        expect { described_class.fill_mandate_in_previous_to!(event) }
          .not_to change(previous, :updated_at)
      end
    end

    context "with previous event other than install or session" do
      it "does not touch previous event" do
        previous = create :tracking_adjust_event,
                          adid:          "ADID",
                          created_at:    1.minute,
                          activity_kind: "FOO"

        expect { described_class.fill_mandate_in_previous_to!(event) }
          .not_to change(previous, :updated_at)
      end
    end
  end
end
