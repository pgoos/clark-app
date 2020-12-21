require 'rails_helper'

RSpec.describe 'Document management', :slow, :browser, type: :feature do

  context 'belonging to a mandate' do

    let(:mandate) { create(:mandate) }
    let!(:document_type) { DocumentType.mandate_document }
    let(:selects) { { document_document_type_id: document_type.name } }
    let(:resource) { create(:document, documentable_type: Mandate, documentable_id: mandate.id, document_type: document_type) }

    before :each do
      login_super_admin
    end

    it 'creates a new document', skip: "excluded from nightly, review" do
      visit new_admin_mandate_document_path(locale: locale, mandate_id: mandate.id)
      i_select_options(selects)
      attach_file(:document_asset, File.join(Rails.root, 'spec', 'support', 'assets', 'mandate.pdf'))
      a_resource_is_created(Document)
      i_see_text_fields([
        document_type.name,
        number_to_human_size(5300, units: :bytes),
        document_type.filename_with_extension(mandate) ])
    end
    #
    it "sees a list of a mandate's documents" do
      resource
      visit admin_mandate_documents_path(locale: locale, mandate_id: mandate.id)
      i_see_text_fields([
        document_type.name,
        number_to_human_size(5300, units: :bytes),
        document_type.filename_with_extension(mandate) ])
    end

    it 'updates an existing document' do
      visit edit_admin_mandate_document_path(locale: locale, mandate_id: mandate.id, id: resource.id)
      i_select_options(selects)
      attach_file(:document_asset, File.join(Rails.root, 'spec', 'support', 'assets', 'mandate.pdf'))
      a_resource_is_updated(Document)
      i_see_text_fields([
        document_type.name,
        number_to_human_size(5300, units: :bytes),
        document_type.filename_with_extension(mandate) ])
    end
  end

  context 'belonging to a product' do
    let(:product) { create(:product) }
    let!(:document_type) { create(:document_type, name: 'Product Specs', template: '') }
    let(:selects) { { document_document_type_id: document_type.name } }
    let(:resource) { create(:document, documentable_type: Product, documentable_id: product.id, document_type: document_type) }

    before :each do
      login_super_admin
    end

    it 'creates a new document' do
      visit new_admin_product_document_path(locale: locale, product_id: product.id)
      i_select_options(selects)
      attach_file(:document_asset, File.join(Rails.root, 'spec', 'support', 'assets', 'mandate.pdf'))
      a_resource_is_created(Document)
      i_see_text_fields([
        document_type.name,
        number_to_human_size(5300, units: :bytes),
        document_type.filename_with_extension(product) ])
    end
    #
    it "sees a list of a product's documents" do
      resource
      visit admin_product_documents_path(locale: locale, product_id: product.id)
      i_see_text_fields([
        document_type.name,
        number_to_human_size(5300, units: :bytes),
        document_type.filename_with_extension(product) ])
    end

    it 'updates an existing document' do
      visit edit_admin_product_document_path(locale: locale, product_id: product.id, id: resource.id)
      i_select_options(selects)
      attach_file(:document_asset, File.join(Rails.root, 'spec', 'support', 'assets', 'mandate.pdf'))
      a_resource_is_updated(Document)
      i_see_text_fields([
        document_type.name,
        number_to_human_size(5300, units: :bytes),
        document_type.filename_with_extension(product) ])
    end
  end
end
