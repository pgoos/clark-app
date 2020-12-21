# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Estimations::InitialIncome::Gross do
  subject { described_class.new(mandate.birthdate, 50_000 * 100) }

  let(:mandate) { build_stubbed(:mandate, birthdate: Date.new(1985, 1, 1)) }

  it { expect(described_class).to have_constant(:AGE_AT_JOB_ENTRY) }
  it { expect(described_class).to have_constant(:EARNING_POINT_THRESHOLD) }

  describe "#call" do
    before { Timecop.freeze(Date.new(2018, 11, 13)) }

    after { Timecop.return }

    context "when customer older than 25" do
      it { expect(subject.call).to eq(309345) }
    end

    context "when customer 25 or less" do
      let(:mandate) { build_stubbed(:mandate, birthdate: Date.new(2000, 1, 1)) }

      it { expect(subject.call).to eq(504911) }
    end
  end
end
