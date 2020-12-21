# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FondsFinanz::StockTransferController, :integration, type: :controller do
  describe "transfer" do
    let(:admin) { create(:admin, role: role) }
    let(:permission) { Permission.where(controller: "admin/fonds_finanz/stock_transfer", action: "list_products") }
    let(:role) { create(:role, permissions: permission) }
    let(:accepted_mandate) { create(:mandate, :accepted) }
    let!(:products) do
      [
        create(:product, takeover_possible: true, state: "details_available", plan: plan, mandate: accepted_mandate),
        create(:product, takeover_possible: true, state: "details_available", plan: plan)
      ]
    end
    let(:plan) { create(:plan) }
    let!(:subcompany) { create(:subcompany, pools: ["fonds_finanz"], plans: [plan]) }

    before { sign_in(admin) }

    it "returns products" do
      get "list_products", params: { locale: :de }
      expect(assigns(:products)).to include(products[0])
      expect(assigns(:products).size).to eq 1
    end
  end
end
