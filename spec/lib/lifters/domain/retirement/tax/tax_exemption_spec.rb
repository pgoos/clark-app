# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::Tax::TaxExemption do
  subject { described_class.(13_952, 18) }

  it { expect(subject).to eq 14518 }
end
