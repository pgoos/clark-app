# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CompaniesController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/companies")) }
  let(:admin) { create(:admin, role: role) }

  before { login_admin(admin) }

  describe "POST /" do
    let(:params) do
      attributes_for(:company).merge(
        info_phone: "+55 12345", damage_phone: "+55 12345", gkv_whitelisted: true
      )
    end

    it "creates a new subcompany" do
      post :create, params: {locale: :de, company: params}
      expect(Company.count).to eq 1
      company = Company.first
      expect(company.name).to eq params[:name]
      expect(company.street).to eq params[:street]
      expect(company.house_number).to eq params[:house_number]
      expect(company.zipcode).to eq params[:zipcode]
      expect(company.gkv_whitelisted).to eq true
    end
  end

  describe "PUT /" do
    let(:company) { create(:company) }
    let(:new_name) { "New name" }
    let(:new_street) { "New street" }
    let(:params) { company.attributes.merge("name" => new_name, "street" => new_street) }

    it "updates the company correctly" do
      patch :update, params: {locale: :de, id: company.id, company: params}
      company.reload
      expect(company.name).to eq new_name
      expect(company.street).to eq new_street
    end
  end
end
