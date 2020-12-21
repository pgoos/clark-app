# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Estimations::InitialIncome::Net, :integration do
  subject { described_class.new(Date.new(1985, 1, 1), 50_000 * 100) }

  before do
    create :retirement_elderly_deductible, deductible_max_amount_cents: 0, deductible_percentage: 0
    create :retirement_taxable_share, year: 2052, taxable_share_state_percentage: 10_000
    create :retirement_income_tax, income_cents: 2_400_000, income_tax_percentage: 1_613
  end

  describe "#call" do
    before { Timecop.freeze(Date.new(2018, 11, 13)) }

    after { Timecop.return }

    it { expect(subject.call).to eq(140_333) }
  end
end
