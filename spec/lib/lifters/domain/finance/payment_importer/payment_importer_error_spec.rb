# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::PaymentImporterError do
  it "define FirstNameInFileNotFound" do
    expect(described_class.superclass).to eq(StandardError)
  end
end
