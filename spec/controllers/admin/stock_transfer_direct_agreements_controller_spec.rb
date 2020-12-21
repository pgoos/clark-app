# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::StockTransferDirectAgreementsController, :integration, type: :controller do
  let(:role)  { create(:role, permissions: Permission.where(controller: "admin/stock_transfer_direct_agreements")) }
  let(:admin) { create(:admin, role: role) }

  before do
    sign_in(admin)
  end

  it "should open list_new_entities for AXA" do
    get :list_new_entities, params: {locale: :de, company_label: "axa"}
    expect(response).to be_ok
    expect(subject).to render_template(:show)
  end

  it "should transfer a given list of entities" do
    company_ident = Domain::StockTransfer::Axa.company_idents.first
    company = create(:company, ident: company_ident)
    category = create(:category)

    entities_to_transfer = [create(:mandate, :accepted), create(:mandate, :accepted)].sort_by(&:id)

    entities_to_transfer.each do |mandate|
      inquiry = create(:inquiry, mandate: mandate, company: company)
      inquiry.inquiry_categories.create!(category: category)
    end

    expect_any_instance_of(Domain::StockTransfer::Axa)
      .to receive(:request_stock_transfer)
      .with(entities_to_transfer)
      .and_return(transferred_entities: entities_to_transfer, errors: [])

    ids = entities_to_transfer.map(&:id).map(&:to_s)
    post :request_transfer, params: {locale: :de, company_label: "axa", entity_ids: ids}

    expect(response).to be_ok
    expect(subject).to render_template(:show)
  end
end
