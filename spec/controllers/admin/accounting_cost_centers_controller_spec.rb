# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AccountingCostCentersController, :integration, type: :controller do
  include SettingsHelpers

  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/accounting_cost_centers")) }
  let(:admin) { create(:admin, role: role) }

  let(:positive_integer) { (rand * 100).round + 1 }
  let(:expected_name) { "cost center #{positive_integer}" }
  let(:params) { {locale: I18n.locale} }

  before do
    allow(Features).to receive(:active?).and_return(true)
    @old_locale = I18n.locale
    I18n.locale = :de
    sign_in(admin)
  end

  after do
    I18n.locale = @old_locale
  end

  context "index" do
    it "operates on an empty collection" do
      get :index, params: params
      assert_response :success
    end

    it "operates with elements" do
      create(:cost_center)
      get :index, params: params
      assert_response :success
    end
  end

  context "new" do
    it "shows the new form" do
      get :new, params: params
      assert_response :success
    end
  end

  context "create" do
    before do
      params[:accounting_cost_center] = {name: expected_name}
    end

    it "allows to create values" do
      expect {
        post :create, params: params
      }.to change { Accounting::CostCenter.count }.by(1)
    end

    it "passes the params" do
      post :create, params: params
      expect(Accounting::CostCenter.last.name).to eq(expected_name)
    end
  end

  context "exists" do
    let(:cost_center) { create(:cost_center, name: "other name") }

    before do
      params[:id] = cost_center.id
    end

    it "shows the edit form" do
      get :edit, params: params
      assert_response :success
    end

    it "allows to update values" do
      params[:accounting_cost_center] = {name: expected_name}
      patch :update, params: params
      expect(Accounting::CostCenter.last.name).to eq(expected_name)
    end

    it "allows to delete values" do
      expect {
        delete :destroy, params: params
      }.to change { Accounting::CostCenter.count }.by(-1)
    end

    it "cannot delete values, if there are transactions attached" do
      create(:accounting_transaction, cost_center: cost_center)
      expect {
        delete :destroy, params: params
      }.to change { Accounting::CostCenter.count }.by(0)
    end
  end
end
