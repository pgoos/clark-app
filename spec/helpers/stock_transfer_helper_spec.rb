# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockTransferHelper do
  context "active views configured from settings" do
    before do
      allow(Settings).to receive_message_chain(:pools, :fonds_finanz).and_return(view_settings[:fonds_finanz])
      allow(Settings).to receive_message_chain(:pools, :quality_pool).and_return(view_settings[:qualitypool])
      allow(Settings).to receive_message_chain(:ops_ui, :cms, :render_stock_transfer_direct_agreements_list)
        .and_return(view_settings[:stock_transfer_direct_agreements])
    end

    describe "#active_views" do
      let(:view_settings) do
        {
          fonds_finanz: true,
          qualitypool: true,
          stock_transfer_direct_agreements: true
        }
      end

      it "returns list of active views" do
        expect(described_class.active_views).to match_array(view_settings.keep_if { |_k, v| v }.keys)
      end
    end

    shared_examples "path array is returned" do |correct_array|
      it { expect(described_class.stock_transfer_path_array).to eq(correct_array) }
    end

    describe "#stock_transfer_path_array" do
      it_behaves_like "path array is returned", %i[admin fonds_finanz stock_transfer transfer] do
        let(:view_settings) do
          {
            fonds_finanz: true,
            qualitypool: false,
            stock_transfer_direct_agreements: true
          }
        end
      end

      it_behaves_like "path array is returned", %i[admin qualitypool stock_transfer list_products] do
        let(:view_settings) do
          {
            fonds_finanz: false,
            qualitypool: true,
            stock_transfer_direct_agreements: true
          }
        end
      end

      it_behaves_like "path array is returned", %i[admin stock_transfer_direct_agreements] do
        let(:view_settings) do
          {
            fonds_finanz: false,
            qualitypool: false,
            stock_transfer_direct_agreements: true
          }
        end
      end

      context "all views are deactivated" do
        let(:view_settings) do
          {
            fonds_finanz: false,
            qualitypool: false,
            stock_transfer_direct_agreements: false
          }
        end

        it "returns empty array" do
          expect(described_class.stock_transfer_path_array).to eq([])
        end
      end
    end
  end
end
