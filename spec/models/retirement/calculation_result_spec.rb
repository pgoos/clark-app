# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::CalculationResult, type: :model do
  it { is_expected.to belong_to(:retirement_cockpit) }
end
