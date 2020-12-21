# frozen_string_literal: true

require "rails_helper"

describe Domain::Interactions::Advice do
  subject { described_class.new(mandate: mandate, interaction: interaction) }

  describe "#dispatch" do
    let(:mandate) { create :mandate, last_advised_at: last_advised_at }
    let(:interaction) { build(:interaction_advice, mandate: mandate) }

    context "when first advice of the day" do
      let(:last_advised_at) { 2.days.ago }

      it do
        subject.dispatch
        expect(interaction).to be_persisted
      end

      it do
        subject.dispatch
        parsed_date = Date.parse(mandate.last_advised_at).strftime("%d-%m-%Y")
        expect(parsed_date).to eq Time.current.strftime("%d-%m-%Y")
      end

      it "notifies the customer" do
        expect(interaction).to receive(:notify_customer).with(true)
        subject.dispatch
      end

      it_behaves_like "when product is already advised in advice spec"
    end

    context "when its not the first advice of the day" do
      let(:last_advised_at) { Time.zone.now }

      it "should not create a interaction and raise MandateAdvisedTodayError error" do
        expect { subject.dispatch }.to raise_error(Domain::Interactions::MandateAdvisedTodayError)
      end

      it_behaves_like "when product is already advised in advice spec"
    end

    context "when it's being called concurrently" do
      let(:last_advised_at) { 2.days.ago }

      it "dispatches advice only once", truncation: true do
        limit = 3
        pool = Concurrent::FixedThreadPool.new(limit)

        limit.times do
          pool.post do
            interaction = build(:interaction_advice)

            allow(interaction).to receive(:notify_customer).with(true)

            dipatcher = Domain::Interactions::Advice.new(mandate: mandate, interaction: interaction)
            dipatcher.dispatch
          end
        end
        pool.shutdown
        pool.wait_for_termination
        expect(Interaction::Advice.count).to eq 1
      end
    end
  end
end
