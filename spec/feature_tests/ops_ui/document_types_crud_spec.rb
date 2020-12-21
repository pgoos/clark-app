require 'rails_helper'

RSpec.describe 'Document type management', :slow, :browser, type: :feature do

  context 'when a permitted admin is logged in' do

    let!(:resource) { DocumentType.last }

    let(:fill_ins) {{ document_type_name:       'Ed',
                      document_type_template:   '',
                      document_type_key:        "west",
                      document_type_description: '4, 5, 6, pick up sticks' }}

    before :each do
      login_super_admin
    end

    it 'creates a new document type' do
      visit new_admin_document_type_path(locale: locale)
      i_fill_in_text_fields(fill_ins)
      a_resource_is_created(DocumentType)
      i_see_text_fields(fill_ins.values)
    end

    it 'sees the last created document type in the index page' do
      resource
      visit admin_document_types_path(locale: locale, limit: 100)
      i_see_text_fields([
        resource.name,
        resource.key,
        resource.description ])
    end

    it 'updates an existing document type' do
      visit_edit_path(:document_type, resource)
      i_fill_in_text_fields(fill_ins)
      a_resource_is_updated(DocumentType)
      i_see_text_fields(fill_ins.values)
    end

    it 'no delete an existing document type' do
      resource.documents << create(:document)
      visit_index_path(:document_types)
      expect{resource.destroy}.to_not change{DocumentType.count}
    end
  end
end
