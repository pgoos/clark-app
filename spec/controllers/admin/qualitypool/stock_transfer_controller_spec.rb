# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Qualitypool::StockTransferController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/qualitypool/stock_transfer")) }
  let(:admin) { create(:admin, role: role) }

  before do
    sign_in(admin)
  end

  it "should open list of current states" do
    get :current_jobs, params: {locale: :de}
    expect(JSON.parse(response.body)).to eq []
  end

  describe "transfer" do
    let(:permission) { Permission.where(controller: "admin/qualitypool/stock_transfer", action: "list_products") }
    let(:role) { create(:role, permissions: permission) }
    let(:accepted_mandate) { create(:mandate, :accepted) }
    let!(:products) do
      [
        create(:product, takeover_possible: true, state: "details_available", plan: plan, mandate: accepted_mandate),
        create(:product, takeover_possible: true, state: "details_available", plan: plan)
      ]
    end
    let(:plan) { create(:plan) }
    let!(:subcompany) { create(:subcompany, pools: ["quality_pool"], plans: [plan]) }

    it "returns products" do
      get "list_products", params: { locale: :de }
      expect(assigns(:products)).to include(products[0])
      expect(assigns(:products).size).to eq 1
    end
  end
end
