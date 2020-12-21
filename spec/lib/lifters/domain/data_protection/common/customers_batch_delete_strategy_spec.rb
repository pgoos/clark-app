# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection::Common::CustomersBatchDeleteStrategy, :integration do
  let!(:admin) { create(:admin) }
  let!(:mandate) { create(:mandate) }
  let!(:inquiry) do
    create(:inquiry, mandate: mandate)
  end

  describe "#run" do
    before do
      allow_any_instance_of(described_class).to(
        receive(:data).and_yield(mandate)
      )
    end

    let(:strategy) { described_class.new(Time.zone.today) }

    let(:call) { strategy.run }

    it "removes mandate provided by #data method" do
      expect { call }.to(
        change_counters
          .from(
            Inquiry => 1,
            Mandate => 1
          )
          .to_zeros
      )
    end
  end
end
