require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe Domain::Products::CsvParser do

  let(:csv_parser) { Domain::Products::CsvParser.new(csv_file) }
  let(:csv_file) { "path/to/file" }
  let(:csv) { [header, row] }

  let(:header) { ["mandate_id", "product id", "number", "product state", "portfolio commission ", "portfolio_commission_period"] }
  let(:row) { [mandate_id, product_id, csv_product_number, state, portfolio_commission_price, portfolio_commission_period] }
  let(:product_id) { "1234567" }
  let(:mandate_id) { "123" }
  let(:csv_product_number) { "ABC123" }
  let(:state) { "under_management" }
  let(:portfolio_commission_price) { "50,40" }
  let(:portfolio_commission_period) { "month" }
  let(:acquisition_commission_price) { "1234" }


  before { allow(CSV).to receive(:read).with(csv_file, { col_sep: ";", encoding: "ISO-8859-1" }).and_return(csv) }

  describe "#update_products" do
    subject { csv_parser.update_products }

    context 'when product with given id and mandate_id exists' do
      let(:product_id) { product.id }
      let(:mandate_id) { mandate.id }
      let(:db_product_number) { csv_product_number }
      let!(:product) { create :product, mandate: mandate, number: db_product_number,
                                                    state: "details_available",
                                                    portfolio_commission_price: "111",
                                                    portfolio_commission_period: "year",
                                                    acquisition_commission_price: "5000",
                                                    acquisition_commission_payouts_count: 5 }
      let!(:mandate) { create :mandate }

      it 'updates the product' do
        expect{ subject }.to change{ product.reload.state }.from("details_available").to(state)
                        .and change{ product.portfolio_commission_price.to_s }.from("111,00").to("50,40")
                        .and change{ product.portfolio_commission_period }.from("year").to("month")
      end

      context 'when field is left blank in CSV' do
        let(:state) { nil }

        it 'does not update that field' do
          expect{ subject }.to not_change{ product.reload.state }
                          .and change{ product.portfolio_commission_price.to_s }.from("111,00").to("50,40")
                          .and change{ product.portfolio_commission_period }.from("year").to("month")
        end
      end

      context 'when update is invalid' do
        let(:state) { "this_state_does_not_exist" }

        it 'raises an error' do
          expect{ subject }.to raise_error(Domain::Products::CsvParser::ProductUpdateInvalidError)
        end
      end

      describe 'product number matchting' do
        context 'when product number has leading zeros and single dots/spaces inside' do
          let(:db_product_number) { "000.00AB.C 1.2.3" }

          it 'treats number as ok' do
            expect{ subject }.to change{ product.reload.state }.from("details_available").to(state)
                            .and change{ product.portfolio_commission_price.to_s }.from("111,00").to("50,40")
                            .and change{ product.portfolio_commission_period }.from("year").to("month")
          end
        end


        context 'when product number does not match' do
          let(:db_product_number) { "the wrong product number" }

          it 'raises an error' do
            expect{ subject }.to raise_error(Domain::Products::CsvParser::ProductNumberNotMatchingError)
          end
        end

        context 'when product number has extra leading chars other than "0", "." or "  "' do
          let(:db_product_number) { "000100ABC123" }

          it 'raises an error' do
            expect{ subject }.to raise_error(Domain::Products::CsvParser::ProductNumberNotMatchingError)
          end
        end

        context 'when product number is interrupted by char other than single "." or "  "' do
          let(:db_product_number) { "ABC12..3" }

          it 'raises an error' do
            expect{ subject }.to raise_error(Domain::Products::CsvParser::ProductNumberNotMatchingError)
          end
        end
      end
    end

    context 'when product with given id and mandate_id cannot be found' do
      let(:product_id) { "1234567" }
      let(:mandate_id) { "123" }

      it 'raises an error' do
        expect{ subject }.to raise_error(Domain::Products::CsvParser::ProductNotFoundError)
      end
    end

    context 'when one of the headers is missing' do
      before { header.delete("mandate_id") }

      it 'raises an error' do
        expect{ subject }.to raise_error(Domain::Products::CsvParser::InvalidFormatError)
      end
    end

    context 'when one of the rows has unexpected number of columns' do
      before { row.delete_at 0 }

      it 'raises an error' do
        expect{ subject }.to raise_error(Domain::Products::CsvParser::InvalidFormatError)
      end
    end
  end
end
