# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::Generator do
  before do
    allow(SimpleXlsxReader).to receive(:open).with(any_args).and_return(file)
  end

  let(:file) {
    OpenStruct.new(sheets:
                     [OpenStruct.new(rows:
                                       [%w[col1 col2 col3 col4],
                                        [1, "something", 2.3, nil],
                                        [2, "something else", 4.5, "valid value"]])])
  }

  context "#fonds_finanz" do
    it "initialize PaymentImporter with FondsFinanz collection and the file" do
      expect(Domain::Finance::PaymentImporter::Base)
        .to receive(:new).with(Domain::Finance::PaymentImporter::FondsFinanz::Collection, file)
      Domain::Finance::PaymentImporter::Generator.fonds_finanz(file)
    end
  end
end
