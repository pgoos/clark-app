# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::Repositories::MandatesWithTosAcceptedAndNoItems, :integration do
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable RSpec/RepeatedExampleGroupDescription
  skip "VKB functionality. Will be removed in https://clarkteam.atlassian.net/browse/JCLARK-60940" do
    subject { described_class.new(now) }

    let!(:mandate) do
      create(
        :mandate,
        tos_accepted_at: tos_accepted_at
      )
    end

    let(:now) do
      Time.zone.parse("2019-01-01 23:59:59 CEST +02:00")
    end

    context "when tos is accepted" do
      context "when tos was accepted 6 weeks ago" do
        let(:tos_accepted_at) { now.ago(6.weeks) }

        context "when has products" do
          let!(:has_product) { create(:product, mandate: mandate) }

          it "returns nothing" do
            expect { |b| subject.each(&b) }.not_to yield_with_args
          end
        end

        context "when has inquires" do
          let!(:has_inquiry) { create(:inquiry, mandate: mandate) }

          it "returns nothing" do
            expect { |b| subject.each(&b) }.not_to yield_with_args
          end
        end

        context "when has neither products nor inquires" do
          it "returns mandate" do
            expect { |b| subject.each(&b) }.to yield_with_args(mandate)
          end
        end
      end

      context "when tos was accepted 6 weeks ago" do
        let(:tos_accepted_at) { now.ago(6.weeks) }

        it "returns mandate" do
          expect { |b| subject.each(&b) }.to yield_with_args(mandate)
        end
      end

      context "when tos was accepted 6 weeks and 5 days ago" do
        let(:tos_accepted_at) { now.ago(6.weeks).ago(5.days) }

        it "returns mandate" do
          expect { |b| subject.each(&b) }.to yield_with_args(mandate)
        end
      end

      context "when tos was accepted 6 weeks and 6 days ago ago" do
        let(:tos_accepted_at) { now.ago(6.weeks).ago(6.days) }

        it "returns nothing" do
          expect { |b| subject.each(&b) }.not_to yield_with_args
        end
      end
    end

    context "when tos is accepted" do
      let(:tos_accepted_at) { nil }

      it "returns nothing" do
        expect { |b| subject.each(&b) }.not_to yield_with_args
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
  # rubocop:enable RSpec/RepeatedExampleGroupDescription
end
