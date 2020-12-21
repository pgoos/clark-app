# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::StateProduct, type: :model do
  subject { build_stubbed(:retirement_state_product) }

  # Validations
  context "when state is created" do
    it "does not validate the presence of document_date" do
      expect(subject).not_to validate_presence_of(:document_date)
    end
  end

  context "when state is details_available" do
    subject { build_stubbed(:retirement_state_product, state: :details_available) }

    it { is_expected.to validate_presence_of(:state).on(:update) }
  end

  # Callbacks
  # Instance Methods
  describe "#ordered_permitted_fields" do
    it "should return correct permitted fields" do
      expect(subject.ordered_permitted_fields).to match_array(
        %i[
          state
          guaranteed_pension_continueed_payment
          guaranteed_pension_continueed_payment_payment_type
          surplus_retirement_income
          surplus_retirement_income_payment_type
        ]
      )
    end
  end

  # Class Methods
end
