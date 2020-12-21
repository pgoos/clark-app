require 'rails_helper'

RSpec.describe 'Vertical management', :slow, :browser, type: :feature do

  context 'when a permitted admin is logged in' do

    let(:resource) { create(:vertical) }

    before :each do
      login_super_admin
    end

    it 'creates a new vertical' do
      visit_new_path(:vertical)
      i_fill_in_text_fields(vertical_name: 'NewVertical', vertical_ident: 'ABCDE')
      a_resource_is_created(Vertical)
      i_see_text_fields(['NewVertical', 'ABCDE'])
    end

    it 'sees a list of all verticals' do
      resource
      visit_index_path(:verticals)
      i_see_text_fields([
        resource.name,
        I18n.t('activerecord.state_machines.states.active'),
        I18n.l(resource.created_at, format: :number)])
    end

    it 'updates an existing vertical' do
      resource
      visit_edit_path(:vertical, resource)
      i_fill_in_text_fields(vertical_name: 'NewVertical')
      a_resource_is_updated(Vertical)
      i_see_text_fields([
        'NewVertical',
        I18n.t('activerecord.state_machines.states.active'),
        I18n.l(resource.created_at, format: :number)
      ])
    end

    it 'deletes an existing vertical' do
      resource
      visit_index_path(:verticals)
      a_resource_is_deleted(Vertical, delete_path(:vertical, resource))
    end
  end
end
