# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SubcompaniesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/subcompanies")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "POST /" do
    let(:vertical) { create(:vertical) }
    let(:company) { create(:company) }
    let(:params) { attributes_for(:subcompany).merge(vertical_ids: [vertical.id], company_id: company.id) }

    it "creates a new subcompany" do
      post :create, params: {locale: :de, subcompany: params}
      expect(Subcompany.count).to eq 1
      subcompany = Subcompany.first
      expect(subcompany.name).to eq params[:name]
      expect(subcompany.bafin_id).to eq params[:bafin_id]
      expect(subcompany.street).to eq params[:street]
      expect(subcompany.house_number).to eq params[:house_number]
      expect(subcompany.zipcode).to eq params[:zipcode]
      expect(subcompany.company).to eq company
      expect(subcompany.verticals.first).to eq vertical
    end

    context "create a new subcompany with email" do
      let(:params) do
        attributes_for(:subcompany, :with_order_email).merge(vertical_ids: [vertical.id], company_id: company.id)
      end

      before do
        post :create, params: { locale: :de, subcompany: params }
      end

      it "has email" do
        subcompany = assigns(:subcompany)
        expect(subcompany.order_email).not_to be_nil
      end
    end
  end

  describe "PUT /" do
    let(:subcompany) { create(:subcompany) }
    let(:new_name) { "New name" }
    let(:new_street) { "New street" }
    let(:standard_new_contract_sales_channel) { "direct_agreement" }
    let(:standard_new_contract_management_channel) { "fonds_finanz" }
    let(:vertical) { create(:vertical) }
    let(:params) do
      subcompany.attributes.merge(
        "name" => new_name,
        "street" => new_street,
        "standard_new_contract_management_channel" => standard_new_contract_management_channel,
        "standard_new_contract_sales_channel" => standard_new_contract_sales_channel,
        "vertical_ids" => vertical.id.to_s
      )
    end

    it "updates the subcompany correctly" do
      patch :update, params: {locale: :de, id: subcompany.id, subcompany: params}
      subcompany.reload
      expect(subcompany.name).to eq new_name
      expect(subcompany.street).to eq new_street
      expect(subcompany.standard_new_contract_management_channel).to eq standard_new_contract_management_channel
      expect(subcompany.standard_new_contract_sales_channel).to eq standard_new_contract_sales_channel
      expect(subcompany.verticals.first).to eq vertical
    end

    context "update a new subcompany with email" do
      let(:new_email) { "new-email@example.org" }
      let(:params) do
        subcompany.attributes.merge(
          name: new_name,
          street: new_street,
          order_email: new_email,
          vertical_ids: vertical.id.to_s
        )
      end

      before do
        post :update, params: { locale: :de, id: subcompany.id, subcompany: params }
      end

      it "has new email" do
        subcompany = assigns(:subcompany)
        expect(subcompany.order_email).to eq(new_email)
      end
    end
  end
end
