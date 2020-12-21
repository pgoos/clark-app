# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::Repositories::MandatesRejected, :integration do
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable RSpec/RepeatedExampleGroupDescription
  skip "VKB functionality. Will be removed in https://clarkteam.atlassian.net/browse/JCLARK-60940" do
    subject { described_class.new(now) }

    let!(:mandate) do
      create(
        :mandate,
        state: mandate_state,
        created_at: created_at
      )
    end

    let(:now) do
      Time.zone.parse("2019-01-01 23:59:59")
    end

    context "when mandate is rejected" do
      let(:mandate_state) { "rejected" }

      before { Timecop.freeze(now) }

      after { Timecop.return }

      context "when created at :now" do
        let(:created_at) { now }

        it "returns mandate" do
          expect { |b| subject.each(&b) }.to yield_with_args(mandate)
        end
      end

      context "when created a day ago" do
        let(:created_at) { now.ago(1.day) }

        it "returns mandate" do
          expect { |b| subject.each(&b) }.to yield_with_args(mandate)
        end
      end

      context "when created after :now" do
        let(:created_at) { now.next_day.middle_of_day }

        it "returns nothing" do
          expect { |b| subject.each(&b) }.not_to yield_with_args
        end
      end
    end

    context "when mandate isn't rejected" do
      let(:mandate_state) { "accepted" }
      let(:created_at) { now }

      it "returns nothing" do
        expect { |b| subject.each(&b) }.not_to yield_with_args
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
  # rubocop:enable RSpec/RepeatedExampleGroupDescription
end
