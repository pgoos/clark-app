# frozen_string_literal: true

require "spec_helper"
require "lifters/domain/products/check_for_duplication"

RSpec.describe Domain::Products::CheckForDuplication do
  let(:double_repository) { class_double("ProductsRepository") }
  let(:service) { described_class.new(double_repository) }

  describe "#call" do
    context "when there is product with same number and same insurance_holder" do
      before do
        allow(double_repository).to receive(:exists_contract_with_number?).and_return(true)
      end

      it "returns false" do
        existing_number = 1
        expect(service.call(number: existing_number)).to be true
      end

      it "raises an exception number is missing" do
        expect {
          service.call(number: nil)
        }.to raise_error ArgumentError
      end
    end
  end
end

