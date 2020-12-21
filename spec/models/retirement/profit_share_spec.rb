# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::ProfitShare, type: :model do
  describe ".find_by_retirement_age" do
    it { expect(described_class.find_by_retirement_age(65)).to eq 18 }

    context "when age is not in the list" do
      it { expect(described_class.find_by_retirement_age(150)).to eq 0 }
    end
  end
end
