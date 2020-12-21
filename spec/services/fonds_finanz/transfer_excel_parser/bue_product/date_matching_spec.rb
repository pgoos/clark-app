# frozen_string_literal: true

require "rails_helper"
require "services/fonds_finanz/transfer_excel_fixtures"

RSpec.describe FondsFinanz::TransferExcelParser::BueProduct do
  include_context "transfer excel fixtures"

  let(:mandate) do
    instance_double(
      Mandate,
      first_name: first_name,
      last_name: last_name,
      birthdate: Date.strptime(date_of_birth, "%d.%m.%Y").noon.in_time_zone
    )
  end
  let(:product) do
    instance_double(
      Product,
      mandate: mandate,
      takeover_requested?: true,
      termination_pending?: false,
      terminated?: false
    )
  end
  let(:event_double) { instance_double(BusinessEvent) }
  let(:bue_product) { described_class.new(row) }
  let(:const_class) { FondsFinanz::TransferExcelParser }

  before do
    allow(product).to receive_message_chain(:business_events, :where, :last)
                        .and_return(event_double)
    allow(mandate).to receive(:accepted?).and_return(true)
    allow(Mandate).to receive(:where).with(any_args).and_return([])
    arel_double = n_double("arel_double")
    allow(Product).to receive(:includes).with(:mandate, :company).and_return(arel_double)
    allow(arel_double)
      .to receive(:find_by)
      .with(id: product_clark_id)
      .and_return(product)
  end

  [
    %w[19.06.1988 20.06.1988],
    %w[20.06.1988 20.06.1988]
  ].each do |data_set|
    context "clark birthdate is #{data_set[0]}" do
      context "ff birthdate is #{data_set[1]}" do
        let(:date_of_birth) { data_set[0] }

        before do
          row[const_class::KUNDE_GEBURTSDATUM_COL] = data_set[1]
        end

        it "finds match" do
          expect(bue_product.product).not_to be_nil
        end
      end
    end
  end
end
