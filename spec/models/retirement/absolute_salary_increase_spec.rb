# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::AbsoluteSalaryIncrease do
  describe ".find_by_age" do
    it { expect(described_class.find_by_age(25)).to eq 24.89 }

    context "when age is not in the list" do
      it { expect(described_class.find_by_age(150)).to eq 100.0 }
    end
  end
end
