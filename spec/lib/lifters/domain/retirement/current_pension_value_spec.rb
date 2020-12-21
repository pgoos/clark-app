# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::CurrentPensionValue do
  subject { described_class.new(mandate.birthdate) }

  describe "#call" do
    let(:future_value) { instance_double(::Retirement::FuturePointValue) }
    let(:retirement_year) { Domain::Retirement::RetirementYear.new.(mandate.birthdate.year) }

    context "when date is invalid" do
      let(:mandate) { OpenStruct.new(birthdate: OpenStruct.new(day: 30, month: 2)) }

      it { expect { subject.call }.to raise_error ArgumentError }
    end

    context "when valid birthdate" do
      before do
        allow(::Retirement::FuturePointValue).to receive(:find_by_date).with(retirement_date) { future_value }
        allow(future_value).to receive(:pension_value_east)

        subject.call
      end

      context "with non-leap year" do
        let(:mandate) { build_stubbed(:mandate, birthdate: Date.new(1987, 1, 1)) }
        let(:retirement_date) { Date.new(retirement_year, mandate.birthdate.month, mandate.birthdate.day) }

        it { expect(future_value).to have_received(:pension_value_east) }
      end

      context "with leap year (29.02)" do
        let(:mandate) { build_stubbed(:mandate, birthdate: Date.new(1988, 2, 29)) }
        let(:retirement_date) { Date.new(retirement_year, 3, 1) }

        it { expect(future_value).to have_received(:pension_value_east) }
      end
    end

    context "when date of birth is older than 01 Jul 1935" do
      it "pension value returns 0" do
        date_of_birth = Time.zone.parse("30 Jun 1935")

        expect(described_class.new(date_of_birth).call).to be_zero
      end
    end
  end
end
